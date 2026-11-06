import MetalKit

struct NightUniforms {
    var sun: SIMD4<Float>
    /// Normalized world origin xy and viewport extent zw. Origin x is reduced in Double first.
    var viewport: SIMD4<Float>
    var style: SIMD4<Float>
    init(solar: SolarPosition, origin: SIMD2<Double>, span: SIMD2<Double>, style: NightStyle) {
        let d = solar.direction
        sun = SIMD4(Float(d.x), Float(d.y), Float(d.z), 0)
        viewport = SIMD4(Float(SolarPosition.wrap(origin.x, period: 1)), Float(origin.y), Float(span.x), Float(span.y))
        self.style = SIMD4(Float(min(1, max(0, style.maximumOpacity))), Float(max(0.001, style.twilightDegrees)), 0, 0)
    }
}

/// Shared immutable GPU resources. No image texture or per-update bitmap.
final class NightRenderer {
    let device: MTLDevice
    let queue: MTLCommandQueue
    let pipeline: MTLRenderPipelineState
    let lightPipeline: MTLRenderPipelineState?
    init(device: MTLDevice? = MTLCreateSystemDefaultDevice()) throws {
        guard let device, let queue = device.makeCommandQueue(),
              let library = device.makeDefaultLibrary(),
              let vertex = library.makeFunction(name: "nightVertex"),
              let fragment = library.makeFunction(name: "nightFragment") else { throw Failure.unavailable }
        self.device = device; self.queue = queue
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertex
        descriptor.fragmentFunction = fragment
        descriptor.colorAttachments[0].pixelFormat = .rgba16Float
        pipeline = try device.makeRenderPipelineState(descriptor: descriptor)
        let lightDescriptor = MTLRenderPipelineDescriptor()
        lightDescriptor.vertexFunction = library.makeFunction(name: "cityLightVertex")
        lightDescriptor.fragmentFunction = library.makeFunction(name: "cityLightFragment")
        let color = lightDescriptor.colorAttachments[0]!
        color.pixelFormat = .rgba16Float
        color.isBlendingEnabled = true
        color.sourceRGBBlendFactor = .one
        color.destinationRGBBlendFactor = .oneMinusSourceAlpha
        color.sourceAlphaBlendFactor = .one
        color.destinationAlphaBlendFactor = .oneMinusSourceAlpha
        // A light-pipeline failure must not take away the validated shadow.
        lightPipeline = try? device.makeRenderPipelineState(descriptor: lightDescriptor)
    }
    enum Failure: Error { case unavailable }
    @discardableResult
    func encode(_ uniforms: NightUniforms, pass: MTLRenderPassDescriptor, command: MTLCommandBuffer,
                lights: MTLBuffer? = nil, count: Int = 0, lightUniforms: LightUniforms = LightUniforms()) -> Bool {
        guard let encoder = command.makeRenderCommandEncoder(descriptor: pass) else { return false }
        var uniforms = uniforms
        encoder.setRenderPipelineState(pipeline)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<NightUniforms>.stride, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        if let lights, let lightPipeline, count > 0 {
            var lightUniforms = lightUniforms
            encoder.setRenderPipelineState(lightPipeline)
            encoder.setVertexBytes(&uniforms, length: MemoryLayout<NightUniforms>.stride, index: 0)
            encoder.setVertexBuffer(lights, offset: 0, index: 1)
            encoder.setVertexBytes(&lightUniforms, length: MemoryLayout<LightUniforms>.stride, index: 2)
            encoder.setFragmentBytes(&lightUniforms, length: MemoryLayout<LightUniforms>.stride, index: 1)
            let copies = Int(ceil(uniforms.viewport.z)) + 2
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6, instanceCount: count * copies)
        }
        encoder.endEncoding()
        return true
    }
}

struct LightGPU {
    var positionAndVisibility: SIMD4<Float> // projected xy, solar visibility, padding
}

struct LightUniforms {
    var viewport = SIMD4<Float>(0, 0, NightCityLights.Style.diameter, 0) // point size xy, diameter, padding
    var color = SIMD4<Float>(NightCityLights.Style.color, NightCityLights.Style.brightness)
}

/// Slots protect reused shared storage from CPU writes while a command is in flight.
private final class LightBufferSlot {
    let available = DispatchSemaphore(value: 1)
    var buffer: MTLBuffer?
    var revision = -1
}

/// One viewport surface, drawn only for camera, Date, data or lifecycle changes.
/// Static city lights share the shadow's cached astronomy and event-driven rendering.
final class DayNightOverlay: MTKView, MTKViewDelegate {
    let renderer: NightRenderer
    private(set) var uniforms: NightUniforms
    private var lastDate: Date
    private var solar: SolarPosition
    private var hasCamera = false
    private var isSuspended = false
    private var isPresentationVisible = true
    private var needsRender = true
    private var lights: [NightCityLights.Light] = []
    private var lightData: [LightGPU] = []
    private var lightRevision = 0
    private let lightSlots = (0..<3).map { _ in LightBufferSlot() }
    private var hasVisibleLights = false
    private var lightModeMaximumOpacity = Float(NightStyle().maximumOpacity)
    private var appearanceMaximumOpacity: Float {
        traitCollection.userInterfaceStyle == .dark ? 0.42 : lightModeMaximumOpacity
    }
    init(renderer: NightRenderer, date: Date) {
        self.renderer = renderer
        lastDate = date
        solar = SolarPosition(date: date)
        uniforms = NightUniforms(solar: solar, origin: .zero, span: SIMD2(1, 1), style: NightStyle())
        super.init(frame: .zero, device: renderer.device)
        colorPixelFormat = .rgba16Float
        clearColor = MTLClearColorMake(0, 0, 0, 0)
        backgroundColor = .clear; isOpaque = false; isUserInteractionEnabled = false
        isAccessibilityElement = false
        isHidden = true // A restored camera must be supplied before any shadow is drawn.
        framebufferOnly = true; isPaused = true; enableSetNeedsDisplay = true
        presentsWithTransaction = true
        autoResizeDrawable = false; delegate = self
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (overlay: DayNightOverlay, _) in
            overlay.updateAppearance()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(enteredBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(becameActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    required init(coder: NSCoder) { fatalError("Use init(renderer:date:)") }
    deinit { NotificationCenter.default.removeObserver(self) }

    func suspend() {
        isSuspended = true
        isHidden = true
        releaseDrawables()
    }

    /// Reversible presentation pause. `suspend` remains teardown-only.
    func setPresentationVisible(_ visible: Bool) {
        guard isPresentationVisible != visible, !isSuspended else { return }
        isPresentationVisible = visible
        needsRender = true
        if visible {
            becameActive()
        } else {
            isHidden = true
            releaseDrawables()
        }
    }

    @objc private func enteredBackground() {
        isHidden = true
        needsRender = true
        releaseDrawables()
    }

    @objc private func becameActive() {
        guard !isSuspended, isPresentationVisible, window != nil, hasCamera else { return }
        isHidden = false
        needsRender = true
        setNeedsDisplay()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            needsRender = true
            releaseDrawables()
        } else if UIApplication.shared.applicationState != .background {
            becameActive()
        }
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        // The field varies smoothly over tens of points; sample once per point, not per screen pixel.
        let size = CGSize(width: max(1, ceil(bounds.width)), height: max(1, ceil(bounds.height)))
        if drawableSize != size { drawableSize = size; needsRender = true; setNeedsDisplay() }
    }
    private func updateAppearance() {
        guard !isSuspended, hasCamera, uniforms.style.x != appearanceMaximumOpacity else { return }
        uniforms.style.x = appearanceMaximumOpacity
        needsRender = true
        setNeedsDisplay()
    }
    func update(date: Date, origin: SIMD2<Double>, span: SIMD2<Double>, style: NightStyle) {
        guard !isSuspended else { return }
        let dateChanged = date != lastDate
        if dateChanged {
            lastDate = date
            solar = SolarPosition(date: date)
            updateVisibility()
        }
        lightModeMaximumOpacity = Float(min(1, max(0, style.maximumOpacity)))
        var next = NightUniforms(solar: solar, origin: origin, span: span, style: style)
        next.style.x = appearanceMaximumOpacity
        guard dateChanged || !hasCamera || next.sun != uniforms.sun || next.viewport != uniforms.viewport || next.style != uniforms.style else { return }
        hasCamera = true
        uniforms = next
        needsRender = true
        isHidden = !isPresentationVisible || UIApplication.shared.applicationState == .background
        updateVisibleLights()
        setNeedsDisplay()
    }
    func updateLights(_ lights: [NightCityLights.Light]) {
        guard self.lights != lights, !isSuspended else { return }
        self.lights = lights
        lightData = lights.map { light in
            LightGPU(positionAndVisibility: SIMD4(light.position.x, light.position.y, 0, 0))
        }
        updateVisibility()
        updateVisibleLights()
        needsRender = true
        setNeedsDisplay()
    }

    private func updateVisibility() {
        for i in lights.indices {
            let coordinate = lights[i].coordinate
            lightData[i].positionAndVisibility.z = NightCityLights.visibility(elevation: solar.elevation(
                latitude: coordinate.latitude, longitude: coordinate.longitude))
        }
        lightRevision += 1
    }

    private func updateVisibleLights() {
        let camera = uniforms.viewport
        let margin = Float(2 / max(1, bounds.width)) * camera.z
        hasVisibleLights = hasCamera && lightData.contains { light in
            let x = light.positionAndVisibility.x - camera.x
            let periodicX = x - floor(x)
            return light.positionAndVisibility.z > 0 && light.positionAndVisibility.y >= camera.y - margin &&
                light.positionAndVisibility.y <= camera.y + camera.w + margin &&
                (periodicX <= camera.z + margin || periodicX >= 1 - margin)
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    func draw(in view: MTKView) {
        guard needsRender, hasCamera, !isSuspended, isPresentationVisible, window != nil,
              UIApplication.shared.applicationState != .background,
              let pass = currentRenderPassDescriptor, let drawable = currentDrawable,
              let command = renderer.queue.makeCommandBuffer() else { return }
        var slot: LightBufferSlot?
        if hasVisibleLights, renderer.lightPipeline != nil {
            slot = lightSlots.first { $0.available.wait(timeout: .now()) == .success }
            guard let slot else { return } // Completion requests any pending draw.
            let length = lightData.count * MemoryLayout<LightGPU>.stride
            if (slot.buffer?.length ?? 0) < length {
                slot.buffer = renderer.device.makeBuffer(length: max(8192, length * 2), options: .storageModeShared)
                slot.revision = -1
            }
            if let buffer = slot.buffer, slot.revision != lightRevision {
                lightData.withUnsafeBytes { bytes in
                    if let base = bytes.baseAddress { buffer.contents().copyMemory(from: base, byteCount: bytes.count) }
                }
                slot.revision = lightRevision
            }
        }
        var lightUniforms = LightUniforms()
        lightUniforms.viewport.x = Float(bounds.width)
        lightUniforms.viewport.y = Float(bounds.height)
        guard renderer.encode(uniforms, pass: pass, command: command, lights: slot?.buffer,
                              count: lightData.count, lightUniforms: lightUniforms) else {
            slot?.available.signal()
            return
        }
        let availability = slot?.available
        command.addCompletedHandler { [weak self] _ in
            availability?.signal()
            DispatchQueue.main.async { [weak self] in
                guard let self, self.needsRender, !self.isSuspended else { return }
                self.setNeedsDisplay()
            }
        }
        // Present in the same Core Animation transaction as UIScrollView's bounds
        // and the pinned surface frame. Asynchronous command-buffer presentation
        // can otherwise show a previous camera beside the newly scrolled artwork.
        // https://developer.apple.com/documentation/quartzcore/cametallayer/presentswithtransaction
        command.commit()
        command.waitUntilScheduled()
        drawable.present()
        needsRender = false
    }
}
