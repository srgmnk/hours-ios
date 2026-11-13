import XCTest
import MetalKit
@testable import MapHarness

@MainActor final class NightCityBrightnessTests: XCTestCase {
    func testStableIdentityDistributionAndSavedCityDeduplication() throws {
        let url = Bundle.main.url(forResource: "cities", withExtension: "json", subdirectory: "Resources")
            ?? Bundle.main.url(forResource: "cities", withExtension: "json")
        let catalog = try JSONDecoder().decode([CitySearchItem].self, from: Data(contentsOf: XCTUnwrap(url)))
        let provider = NightCityLights(catalog: catalog)
        let base = provider.lights(savedCities: [])
        XCTAssertEqual(base.map(\.id), DecorativeCityIDs.catalogIDs.map { "catalog:" + $0 })
        XCTAssertEqual(base.count, 50)
        let expected: [Float] = [0.30, 0.85, 1, 0.85, 0.70, 1, 0.85, 1, 1, 0.70,
                                 1, 0.50, 0.30, 1, 0.50, 0.30, 0.85, 1, 0.70, 1,
                                 0.50, 0.50, 0.85, 0.70, 1, 0.50, 0.70, 0.70, 0.30, 1,
                                 1, 0.50, 0.30, 0.30, 0.50, 0.70, 1, 1, 0.30, 0.85,
                                 0.70, 0.85, 0.30, 0.50, 1, 0.30, 0.30, 1, 0.50, 0.50]
        // A fixed ID->level oracle catches accidental hash/seed changes across launches.
        let byID = Dictionary(uniqueKeysWithValues: zip(base.map(\.id), expected))
        for light in base.reversed() {
            XCTAssertEqual(light.glowIntensity, byID[light.id])
            let coordinate = try XCTUnwrap(LocalCityCoordinates.byCatalogID[String(light.id.dropFirst(8))])
            XCTAssertEqual(light.coordinate, coordinate)
            XCTAssertEqual(NightCityLights.Light(id: light.id, coordinate: coordinate), light)
        }
        XCTAssertEqual([Float(0.30), 0.50, 0.70, 0.85, 1].map { level in base.filter { $0.glowIntensity == level }.count }, [10, 10, 8, 7, 15])
        XCTAssertEqual(NightCityLights(catalog: catalog.reversed()).lights(savedCities: []), base)
        XCTAssertEqual(NightCityLights.glowIntensity(for: "saved:東京"), 0.85)
        let london = try XCTUnwrap(catalog.first { $0.id == "london-gb" }).asCity
        let saved = City(name: "Fixture", timeZoneID: "Etc/UTC", canonicalID: "city:fixture", latitude: 1, longitude: 2)
        let combined = provider.lights(savedCities: [london, saved, saved])
        XCTAssertEqual(Array(combined.prefix(50)), base)
        XCTAssertEqual(combined.count, 51)
        XCTAssertEqual(combined.last?.glowIntensity, 0.30)
        XCTAssertEqual(provider.lights(savedCities: [saved, london]), combined)
    }

    func testIntensitySurvivesCameraTimeThemeAndPostureChanges() throws {
        let renderer = try NightRenderer()
        let date = Date(timeIntervalSince1970: 1794247200)
        let overlay = DayNightOverlay(renderer: renderer, date: date)
        let lights = NightCityLights().lights(savedCities: [])
        overlay.updateLights(lights)
        let intensities = lights.map(\.glowIntensity)
        for size in [CGSize(width: 393, height: 852), CGSize(width: 382, height: 678),
                     CGSize(width: 475.5, height: 669), CGSize(width: 455.5, height: 669),
                     CGSize(width: 669, height: 476), CGSize(width: 669, height: 456), CGSize(width: 375, height: 669)] {
            overlay.frame.size = size; overlay.layoutIfNeeded()
            for dark in [false, true] {
                overlay.overrideUserInterfaceStyle = dark ? .dark : .light
                for hour in 0..<24 {
                    let instant = date.addingTimeInterval(Double(hour) * 3600)
                    overlay.update(date: instant, origin: SIMD2(Double(hour) / 24, 0), span: SIMD2(0.5, 0.8), style: NightStyle())
                    XCTAssertEqual(overlay.lightData.map { $0.positionAndVisibility.w }, intensities)
                    let solar = SolarPosition(date: instant)
                    for (light, gpu) in zip(lights, overlay.lightData) {
                        XCTAssertEqual(SIMD2(gpu.positionAndVisibility.x, gpu.positionAndVisibility.y), light.position)
                        XCTAssertEqual(gpu.positionAndVisibility.z, NightCityLights.visibility(elevation: solar.elevation(latitude: light.coordinate.latitude, longitude: light.coordinate.longitude)))
                    }
                    let revision = overlay.lightRevision
                    overlay.updateLights(NightCityLights().lights(savedCities: []))
                    XCTAssertEqual(overlay.lightRevision, revision)
                }
            }
        }
        XCTAssertEqual(MemoryLayout<LightGPU>.stride, 16)
        XCTAssertTrue(overlay.isPaused)
    }

    func testGPUKeepsCoreAndFullIntensityExactAndScalesOnlyHalo() throws {
        let renderer = try NightRenderer()
        let library = try XCTUnwrap(renderer.device.makeDefaultLibrary())
        // Frozen pre-polish fragment, linked to the actual production vertex shader.
        let reference = try renderer.device.makeLibrary(source: """
        #include <metal_stdlib>
        using namespace metal;
        struct LightVertex { float4 position [[position]]; float2 local; float4 color; float glowIntensity [[flat]]; };
        fragment float4 referenceLight(LightVertex in [[stage_in]], texture2d<float> sprite [[texture(0)]]) {
            constexpr sampler s(coord::normalized, address::clamp_to_edge, filter::linear);
            return sprite.sample(s, in.local) * in.color.a;
        }
        """, options: nil)
        func pipeline(_ fragment: MTLFunction?) throws -> MTLRenderPipelineState {
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = library.makeFunction(name: "cityLightVertex")
            descriptor.fragmentFunction = fragment
            descriptor.colorAttachments[0].pixelFormat = .rgba16Float
            return try renderer.device.makeRenderPipelineState(descriptor: descriptor)
        }
        let original = try pipeline(reference.makeFunction(name: "referenceLight"))
        let current = try pipeline(library.makeFunction(name: "cityLightFragment"))
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba16Float, width: 84, height: 84, mipmapped: false)
        descriptor.storageMode = .shared; descriptor.usage = [.renderTarget]
        let texture = try XCTUnwrap(renderer.device.makeTexture(descriptor: descriptor))
        func render(_ pipeline: MTLRenderPipelineState, _ intensity: Float, _ visibility: Float = 1) throws -> [UInt16] {
            let pass = MTLRenderPassDescriptor()
            pass.colorAttachments[0].texture = texture
            pass.colorAttachments[0].loadAction = .clear; pass.colorAttachments[0].storeAction = .store
            let command = try XCTUnwrap(renderer.queue.makeCommandBuffer())
            let encoder = try XCTUnwrap(command.makeRenderCommandEncoder(descriptor: pass))
            var uniforms = NightUniforms(solar: SolarPosition(date: Date(timeIntervalSince1970: 0)), origin: .zero, span: SIMD2(1, 1), style: NightStyle())
            var style = LightUniforms(); style.viewport.x = 14; style.viewport.y = 14
            var light = LightGPU(positionAndVisibility: SIMD4(0.5, 0.5, visibility, intensity))
            encoder.setRenderPipelineState(pipeline)
            encoder.setVertexBytes(&uniforms, length: MemoryLayout<NightUniforms>.stride, index: 0)
            encoder.setVertexBytes(&light, length: MemoryLayout<LightGPU>.stride, index: 1)
            encoder.setVertexBytes(&style, length: MemoryLayout<LightUniforms>.stride, index: 2)
            encoder.setFragmentBytes(&style, length: MemoryLayout<LightUniforms>.stride, index: 1)
            encoder.setFragmentTexture(renderer.lightTexture, index: 0)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6, instanceCount: 3)
            encoder.endEncoding(); command.commit(); command.waitUntilCompleted()
            XCTAssertEqual(command.status, .completed)
            var pixels = [UInt16](repeating: 0, count: 84 * 84 * 4)
            pixels.withUnsafeMutableBytes { texture.getBytes($0.baseAddress!, bytesPerRow: 84 * 8, from: MTLRegionMake2D(0, 0, 84, 84), mipmapLevel: 0) }
            return pixels
        }
        let baseline = try render(original, 1)
        XCTAssertEqual(try render(current, 1), baseline)
        XCTAssertTrue(baseline.contains { $0 != 0 })
        for level: Float in [0.30, 0.50, 0.70, 0.85] {
            let pixels = try render(current, level)
            XCTAssertEqual(try render(current, level), pixels)
            for y in 0..<84 {
                for x in 0..<84 {
                    let radius = hypot(Float(x) + 0.5 - 42, Float(y) + 0.5 - 42) / 6
                    for channel in 0..<4 {
                        let i = (y * 84 + x) * 4 + channel
                        if radius <= 1.5 { XCTAssertEqual(pixels[i], baseline[i]) }
                        if radius >= 2 {
                            XCTAssertEqual(Float(Float16(bitPattern: pixels[i])), Float(Float16(bitPattern: baseline[i])) * level, accuracy: 0.001)
                        }
                    }
                }
            }
            XCTAssertTrue(try render(current, level, 0).allSatisfy { $0 == 0 })
        }
    }
}
