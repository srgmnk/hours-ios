import XCTest
import MetalKit
@testable import MapHarness

@MainActor final class MapRenderingCostTests: XCTestCase {
    func testEventDrawCost() throws {
        let renderer = try NightRenderer()
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba16Float, width: 393, height: 852, mipmapped: false)
        descriptor.usage = [.renderTarget, .shaderRead]
        let texture = try XCTUnwrap(renderer.device.makeTexture(descriptor: descriptor))
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = texture
        pass.colorAttachments[0].loadAction = .clear
        pass.colorAttachments[0].storeAction = .store
        let lights = NightCityLights().lights(savedCities: [])
        let data = lights.map { LightGPU(positionAndVisibility: SIMD4($0.position.x, $0.position.y, 1, 0)) }
        let buffer = try XCTUnwrap(data.withUnsafeBytes { bytes in
            renderer.device.makeBuffer(bytes: bytes.baseAddress!, length: bytes.count, options: .storageModeShared)
        })
        let uniforms = NightUniforms(solar: SolarPosition(date: Date(timeIntervalSince1970: 1793235600)),
                                    origin: SIMD2(0.60, 0), span: SIMD2(0.35, 0.75), style: NightStyle())
        var style = LightUniforms(); style.viewport.x = 393; style.viewport.y = 852
        var cpu: [Double] = [], gpu: [Double] = [], elapsed: [Double] = []
        for i in 0..<55 {
            let start = CACurrentMediaTime()
            let command = try XCTUnwrap(renderer.queue.makeCommandBuffer())
            XCTAssertTrue(renderer.encode(uniforms, pass: pass, command: command, lights: buffer, count: data.count, lightUniforms: style))
            let encoded = CACurrentMediaTime()
            command.commit(); command.waitUntilCompleted()
            XCTAssertEqual(command.status, .completed)
            if i >= 5 {
                cpu.append((encoded - start) * 1000)
                gpu.append((command.gpuEndTime - command.gpuStartTime) * 1000)
                elapsed.append((CACurrentMediaTime() - start) * 1000)
            }
        }
        func median(_ values: [Double]) -> Double { values.sorted()[values.count / 2] }
        print("MAP_RENDER_COST base=\(data.count) instances=\(data.count * 3) encode_ms=\(median(cpu)) gpu_ms=\(median(gpu)) completed_ms=\(median(elapsed)) device=\(renderer.device.name)")
    }
}
