import XCTest
import SwiftUI
import MetalKit
@testable import MapHarness

/// Captures the real UIKit label and MTKView renderers at the simulator's scale.
/// Figma exports are comparison fixtures, never production label bitmaps.
@MainActor final class MapLabelLightTests: XCTestCase {
    private func attach(_ view: UIView, _ name: String) {
        let format = UIGraphicsImageRendererFormat(); format.scale = 3
        let image = UIGraphicsImageRenderer(bounds: view.bounds, format: format).image { _ in
            XCTAssertTrue(view.drawHierarchy(in: view.bounds, afterScreenUpdates: true))
        }
        let a = XCTAttachment(image: image); a.name = name; a.lifetime = .keepAlways; add(a)
    }
    private func reference(_ name: String) throws -> UIImage {
        let bundle = Bundle(for: Self.self)
        let url = try XCTUnwrap(bundle.url(forResource: name + "@3x", withExtension: "png"))
        let data = try Data(contentsOf: url)
        return try XCTUnwrap(UIImage(data: data, scale: 3))
    }

    func testExactTypographyAndThemeInvariantRendering() throws {
        let scale = WorldMapMarkerView.labelScale
        for size: CGFloat in [14, 18] {
            let text = WorldMapMarkerView.label("City name +1", size: size)
            let font = try XCTUnwrap(text.attribute(.font, at: 0, effectiveRange: nil) as? UIFont)
            XCTAssertEqual(font.pointSize * scale, size, accuracy: 1e-6)
            XCTAssertTrue(font.fontName.contains("Rounded"))
            XCTAssertTrue(font.fontName.contains(size == 18 ? "Bold" : "Semibold"))
            XCTAssertEqual((text.attribute(.kern, at: 0, effectiveRange: nil) as! CGFloat) * scale,
                           size == 14 ? -0.28 : -0.72, accuracy: 1e-6)
            let label = WorldMapMarkerLabel(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
            label.attributedText = text
            let outline = try XCTUnwrap(label.outlineText)
            let color = try XCTUnwrap(outline.attribute(.strokeColor, at: 0, effectiveRange: nil) as? UIColor)
            XCTAssertEqual(color.cgColor.alpha, 0.3, accuracy: 1e-6)
            let stroke = outline.attribute(.strokeWidth, at: 0, effectiveRange: nil) as! CGFloat
            XCTAssertEqual(stroke / 100 * font.pointSize * scale, 2, accuracy: 1e-6)
            var reference: Data?
            for style in [UIUserInterfaceStyle.light, .dark] {
                label.overrideUserInterfaceStyle = style; label.backgroundColor = UIColor(white: 0.18, alpha: 1)
                let format = UIGraphicsImageRendererFormat(); format.scale = 3
                let image = UIGraphicsImageRenderer(bounds: label.bounds, format: format).image { c in
                    label.layer.render(in: c.cgContext)
                }
                let data = try XCTUnwrap(image.pngData())
                if let reference { XCTAssertEqual(reference, data) } else { reference = data }
            }
        }
    }

    func testLinearPremultiplicationAndResourceReuse() throws {
        let bytes = NightRenderer.linearPremultipliedSprite([128, 64, 0, 128, 0, 0, 0, 0, 128, 128, 128, 255])
        let values = bytes.map { Float(Float16(bitPattern: $0)) }
        XCTAssertEqual(values[0], 128.0 / 255, accuracy: 0.0005)
        XCTAssertEqual(values[1], 0.21404114 * 128 / 255, accuracy: 0.0005)
        XCTAssertEqual(values[3], 128.0 / 255, accuracy: 0.0005)
        XCTAssertEqual(Array(values[4..<8]), [0, 0, 0, 0])
        XCTAssertEqual(values[8], 0.2158605, accuracy: 0.0005)
        let renderer = try NightRenderer()
        XCTAssertEqual(renderer.lightTexture?.pixelFormat, .rgba16Float)
        XCTAssertEqual(renderer.lightTexture?.width, 42)
        XCTAssertEqual(renderer.lightTexture?.height, 42)
    }

    func testCaptureEquivalentBackgroundLabelsAndLights() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene); let host = UIViewController()
        window.rootViewController = host; window.makeKeyAndVisible()
        defer { window.isHidden = true; previous?.makeKeyAndVisible() }
        let panel = UIView(frame: CGRect(x: 0, y: 80, width: 300, height: 500)); host.view.addSubview(panel)
        panel.backgroundColor = UIColor(white: 0.18, alpha: 1)
        let date = ISO8601DateFormatter().date(from: "2026-11-09T12:00:00Z")!
        let city = City(name: "City name", timeZoneID: "Etc/UTC", canonicalID: "city:label-fixture", latitude: 0, longitude: 0)
        for (index, primary) in [false, true].enumerated() {
            let marker = WorldMapMarkerView(cityID: city.id)
            marker.configure(city: city, point: .zero); marker.setPrimary(primary); marker.updateTime(at: date)
            marker.transform = CGAffineTransform(scaleX: WorldMapMarkerView.labelScale, y: WorldMapMarkerView.labelScale)
            marker.center = CGPoint(x: 70 + index * 150, y: 60)
            panel.addSubview(marker)
        }
        for (index, name) in ["City name, City name", "City name +1"].enumerated() {
            let group = WorldMapSharedLabelView(); group.configure(name: name, time: "12:00")
            group.transform = CGAffineTransform(scaleX: WorldMapMarkerView.labelScale, y: WorldMapMarkerView.labelScale)
            group.center = CGPoint(x: 150, y: 145 + index * 65); panel.addSubview(group)
        }
        let figma = UIImageView(image: try reference("figma-map-label")); figma.frame = CGRect(x: 115, y: 255, width: figma.image!.size.width, height: figma.image!.size.height); panel.addSubview(figma)
        for dark in [false, true] {
            window.overrideUserInterfaceStyle = dark ? .dark : .light
            try await Task.sleep(for: .milliseconds(120)); attach(panel, "labels-equivalent-\(dark ? "dark" : "light")")
        }
        panel.subviews.forEach { $0.removeFromSuperview() }
        // Equal opaque backgrounds derived from dark-map land/ocean colors.
        // Separate patch captures below retain the watercolor texture itself.
        let backgrounds: [(String, UIColor)] = [("land", UIColor(red: 0.16, green: 0.19, blue: 0.12, alpha: 1)),
                                               ("ocean", UIColor(red: 0.025, green: 0.07, blue: 0.10, alpha: 1))]
        let renderer = try NightRenderer()
        for (name, background) in backgrounds {
            for dark in [false, true] {
                window.overrideUserInterfaceStyle = dark ? .dark : .light
                panel.backgroundColor = background
                let artwork = try XCTUnwrap(UIImage(named: "worldmap", in: .main,
                    compatibleWith: UITraitCollection(userInterfaceStyle: .dark))?.cgImage)
                let center = name == "land" ? CGPoint(x: 0.32, y: 0.51) : CGPoint(x: 0.72, y: 0.55)
                let crop = CGRect(x: center.x * CGFloat(artwork.width) - 150,
                                  y: center.y * CGFloat(artwork.height) - 150, width: 300, height: 300)
                let patch = UIImage(cgImage: try XCTUnwrap(artwork.cropping(to: crop)), scale: 3, orientation: .up)
                for x: CGFloat in [0, 100] {
                    let backdrop = UIImageView(image: patch); backdrop.frame = CGRect(x: x, y: 0, width: 100, height: 100)
                    panel.addSubview(backdrop)
                }
                let expected = UIImageView(image: try reference("figma-night-light"))
                expected.frame = CGRect(x: 43, y: 43, width: 14, height: 14); panel.addSubview(expected)
                let overlay = DayNightOverlay(renderer: renderer, date: date)
                overlay.overrideUserInterfaceStyle = .light // isolate light color from theme-specific solar opacity
                overlay.frame = CGRect(x: 100, y: 0, width: 100, height: 100); panel.addSubview(overlay)
                let light = NightCityLights.Light(id: "fixture", coordinate: .init(latitude: 0, longitude: 0))
                overlay.updateLights([light]); overlay.update(date: date, origin: .zero, span: SIMD2(1, 1), style: NightStyle(maximumOpacity: 0))
                overlay.layoutIfNeeded()
                // Isolate sprite compositing from solar shadow, using the real surface.
                overlay.uniforms.style.x = 0; overlay.lightData[0].positionAndVisibility.z = 1
                overlay.lightData[0].positionAndVisibility.w = 1 // approved full-intensity reference
                overlay.lightRevision += 1; overlay.updateVisibleLights(); overlay.needsRender = true; overlay.setNeedsDisplay()
                try await Task.sleep(for: .milliseconds(150)); attach(panel, "lights-equivalent-\(name)-\(dark ? "dark" : "light")")
                print("LIGHT_SURFACE shadow=\(overlay.uniforms.style.x) scale=\(overlay.contentScaleFactor) drawable=\(overlay.drawableSize) colorspace=\(String(describing: (overlay.layer as? CAMetalLayer)?.colorspace))")
                expected.removeFromSuperview(); overlay.removeFromSuperview()
                attach(panel, "lights-background-\(name)-\(dark ? "dark" : "light")")
                panel.subviews.forEach { $0.removeFromSuperview() }
            }
        }
    }
}
