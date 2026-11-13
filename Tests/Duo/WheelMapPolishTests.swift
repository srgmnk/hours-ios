import XCTest
import SwiftUI
@testable import MapHarness

@MainActor final class WheelMapPolishTests: XCTestCase {
    func testConventionalMapAndListScreenshots() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        let defaults = UserDefaults.standard
        let savedPreference = defaults.object(forKey: CityViewPreference.storageKey)
        defer {
            window.isHidden = true; previous?.makeKeyAndVisible()
            defaults.set(savedPreference, forKey: CityViewPreference.storageKey)
        }
        let cities = [City(name: "Bangkok", timeZoneID: "Asia/Bangkok", canonicalID: "polish-bangkok", latitude: 13.7563, longitude: 100.5018),
                      City(name: "London", timeZoneID: "Europe/London", canonicalID: "polish-london", latitude: 51.5074, longitude: -0.1278)]
        let data = try JSONEncoder().encode(cities)
        let store = CityStore(storage: .init(read: { _ in data }, write: { _, _ in }, sharedDefaults: { _ in nil }, reloadWidgets: {}))
        for dark in [false, true] {
            for name in ["map", "basic", "compact", "cards"] {
                defaults.set(name == "map" ? "basic" : name, forKey: CityViewPreference.storageKey)
                let model = TimeDialViewModel()
                model.tickerTask?.cancel(); model.beginDialDrag()
                model.baseTime = ISO8601DateFormatter().date(from: "2026-11-09T18:00:00Z")!
                let screen = TimeDialScreen(viewModel: model, cityPresentation: name == "map" ? .map : .list)
                let host = UIHostingController(rootView: screen.environmentObject(store)
                    .environment(\.appTheme, dark ? .dark : .light).preferredColorScheme(dark ? .dark : .light))
                window.rootViewController = host; window.makeKeyAndVisible()
                try await Task.sleep(for: .milliseconds(400))
                host.view.layoutIfNeeded()
                let image = UIGraphicsImageRenderer(bounds: host.view.bounds).image { _ in
                    XCTAssertTrue(host.view.drawHierarchy(in: host.view.bounds, afterScreenUpdates: true))
                }
                let attachment = XCTAttachment(image: image)
                attachment.name = "wheel-\(name)-\(dark ? "dark" : "light")"
                attachment.lifetime = .keepAlways; add(attachment)
                if name == "map" {
                    func findMap(_ view: UIView) -> WorldMapScrollView? {
                        (view as? WorldMapScrollView) ?? view.subviews.lazy.compactMap { findMap($0) }.first
                    }
                    let map = try XCTUnwrap(findMap(host.view))
                    let mapImage = UIGraphicsImageRenderer(bounds: map.bounds).image { _ in
                        XCTAssertTrue(map.drawHierarchy(in: map.bounds, afterScreenUpdates: true))
                    }
                    // The center just above the bottom edge is inside the wheel
                    // arc, clear of ticks/controls. Its map pixels must stay exposed.
                    for offset: CGFloat in [-8, 0, 8] {
                        let point = CGPoint(x: host.view.bounds.midX + offset, y: host.view.bounds.maxY - 8)
                        let local = map.convert(point, from: host.view)
                        let expected = try patchAverage(mapImage, at: CGPoint(x: local.x - map.bounds.minX, y: local.y - map.bounds.minY))
                        let actual = try patchAverage(image, at: point)
                        // Hierarchy snapshots resample the watercolor at fractional
                        // view origins. Compare a small patch, not individual texels.
                        for (a, b) in zip(actual, expected) { XCTAssertEqual(a, b, accuracy: 4) }
                    }
                }
            }
        }
    }

    private func patchAverage(_ image: UIImage, at point: CGPoint) throws -> [Double] {
        let source = try XCTUnwrap(image.cgImage)
        let side = 31
        let rect = CGRect(x: floor(point.x * image.scale) - 15,
                          y: floor(point.y * image.scale) - 15,
                          width: CGFloat(side), height: CGFloat(side))
        let crop = try XCTUnwrap(source.cropping(to: rect))
        var bytes = [UInt8](repeating: 0, count: side * side * 4)
        try bytes.withUnsafeMutableBytes { buffer in
            let context = try XCTUnwrap(CGContext(data: buffer.baseAddress, width: side, height: side, bitsPerComponent: 8, bytesPerRow: side * 4,
                                                 space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
            context.draw(crop, in: CGRect(x: 0, y: 0, width: CGFloat(side), height: CGFloat(side)))
        }
        return (0..<3).map { channel in
            stride(from: channel, to: bytes.count, by: 4).reduce(0.0) { $0 + Double(bytes[$1]) } / Double(side * side)
        }
    }
}
