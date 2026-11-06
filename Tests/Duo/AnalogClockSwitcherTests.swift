import XCTest
import SwiftUI
@testable import MapHarness

@MainActor final class AnalogClockSwitcherTests: XCTestCase {
    private func instant(_ value: String) -> Date { ISO8601DateFormatter().date(from: value)! }

    private func check(_ date: String, zone: String, hour: Double, minute: Double, second: Double,
                       file: StaticString = #filePath, line: UInt = #line) {
        let angles = AnalogClockAngles(instant: instant(date), timeZone: TimeZone(identifier: zone)!)
        XCTAssertEqual(angles.hour, hour, accuracy: 0.0001, file: file, line: line)
        XCTAssertEqual(angles.minute, minute, accuracy: 0.0001, file: file, line: line)
        XCTAssertEqual(angles.second, second, accuracy: 0.0001, file: file, line: line)
    }

    func testDeterministicLocalTimeAndFractionalHands() {
        check("2026-10-29T03:15:30Z", zone: "Asia/Bangkok", hour: 307.75, minute: 93, second: 180)
        check("2026-10-29T03:15:30Z", zone: "Asia/Kathmandu", hour: 270.25, minute: 3, second: 180)
        check("2026-10-29T00:00:00Z", zone: "Etc/UTC", hour: 0, minute: 0, second: 0)
        check("2026-10-29T12:00:00Z", zone: "Etc/UTC", hour: 0, minute: 0, second: 0)
    }

    func testDSTSpringGapAndRepeatedFallHour() {
        check("2026-03-08T06:59:59Z", zone: "America/New_York", hour: 59.9916667, minute: 359.9, second: 354)
        check("2026-03-08T07:00:00Z", zone: "America/New_York", hour: 90, minute: 0, second: 0)
        check("2026-11-01T05:30:00Z", zone: "America/New_York", hour: 45, minute: 180, second: 0)
        check("2026-11-01T06:30:00Z", zone: "America/New_York", hour: 45, minute: 180, second: 0)
    }

    func testWheelForwardBackwardInertiaAndResetUseOneInstant() async throws {
        let model = TimeDialViewModel()
        model.beginDialDrag()
        model.baseTime = instant("2026-10-29T03:00:00Z")
        let zone = TimeZone(identifier: "Asia/Bangkok")!
        model.updateDialRotation(-15)
        XCTAssertEqual(model.selectedInstant, instant("2026-10-29T04:00:00Z"))
        XCTAssertEqual(AnalogClockAngles(instant: model.selectedInstant, timeZone: zone).hour, 330)
        model.updateDialRotation(15)
        XCTAssertEqual(model.selectedInstant, instant("2026-10-29T02:00:00Z"))
        XCTAssertEqual(AnalogClockAngles(instant: model.selectedInstant, timeZone: zone).hour, 270)
        model.endDialDrag(currentRotation: 15, predictedRotation: 35)
        let before = model.selectedInstant
        try await Task.sleep(for: .milliseconds(150))
        XCTAssertLessThan(model.selectedInstant, before)
        model.resetToNow()
        XCTAssertEqual(model.selectedInstant, model.now)
        XCTAssertEqual(AnalogClockAngles(instant: model.selectedInstant, timeZone: zone),
                       AnalogClockAngles(instant: model.now, timeZone: zone))
    }

    func testPrimaryReplacementDeletionAndEmptyFallback() throws {
        let cities = [City(name: "Bangkok", timeZoneID: "Asia/Bangkok"),
                      City(name: "New York", timeZoneID: "America/New_York")]
        let data = try JSONEncoder().encode(cities)
        let store = CityStore(storage: .init(read: { _ in data }, write: { _, _ in },
                                            sharedDefaults: { _ in nil }, reloadWidgets: {}))
        let date = instant("2026-10-29T03:00:00Z")
        func hour() -> Double {
            AnalogClockAngles(instant: date, timeZone: store.cities.first?.timeZone ?? .current).hour
        }
        XCTAssertEqual(hour(), 300)
        store.cities.reverse()
        XCTAssertEqual(hour(), 330)
        store.cities.removeFirst()
        XCTAssertEqual(hour(), 300)
        store.cities[0] = City(name: "Tokyo", timeZoneID: "Asia/Tokyo")
        XCTAssertEqual(hour(), 0)
        store.cities.removeAll()
        XCTAssertEqual(hour(), AnalogClockAngles(instant: date, timeZone: .current).hour)
    }

    func testButtonAndIconGeometryAndAppearanceSnapshots() throws {
        let date = instant("2026-10-29T03:08:00Z")
        for dark in [false, true] {
            for map in [false, true] {
                let button = TimeDialScreen.CityPresentationButton(
                    presentation: .constant(map ? .map : .list), selectedInstant: date,
                    primaryTimeZone: TimeZone(identifier: "Asia/Bangkok")!)
                    .environment(\.appTheme, dark ? .dark : .light)
                    .environment(\.colorScheme, dark ? .dark : .light)
                let host = UIHostingController(rootView: button)
                XCTAssertEqual(host.sizeThatFits(in: CGSize(width: 200, height: 200)), CGSize(width: 48, height: 48))
                let renderer = ImageRenderer(content: button.padding(12)
                    .background(dark ? AppTheme.dark.screenBackground : AppTheme.light.screenBackground))
                renderer.scale = 3
                let image = try XCTUnwrap(renderer.uiImage)
                let attachment = XCTAttachment(image: image)
                attachment.name = "Switcher-\(map ? "Map-clock" : "List-artwork")-\(dark ? "Dark" : "Light")"
                attachment.lifetime = .keepAlways
                add(attachment)
            }
        }
        let icon = UIHostingController(rootView: AnalogClockSwitcherIcon(instant: date, timeZone: .gmt))
        XCTAssertEqual(icon.sizeThatFits(in: CGSize(width: 100, height: 100)), CGSize(width: 36, height: 36))
    }
    // Host the real screen, so a stale geometry builder or missed model/store
    // notification fails even when the angle helper itself is correct.
    func testClockTracksTheRealScreenThroughWheelAndPrimaryChanges() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        let model = TimeDialViewModel()
        // A periodic model publication must not hide a missed city-store update.
        model.tickerTask?.cancel()
        let cities = [City(name: "Bangkok", timeZoneID: "Asia/Bangkok"),
                      City(name: "New York", timeZoneID: "America/New_York")]
        let data = try JSONEncoder().encode(cities)
        let store = CityStore(storage: .init(read: { _ in data }, write: { _, _ in },
                                            sharedDefaults: { _ in nil }, reloadWidgets: {}))
        let screen = TimeDialScreen(viewModel: model, cityPresentation: .map)
        let host = UIHostingController(rootView: screen.environmentObject(store)
            .environment(\.appTheme, .light).preferredColorScheme(.light))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true; previous?.makeKeyAndVisible() }
        model.beginDialDrag()
        model.baseTime = instant("2026-10-29T03:08:00Z")
        try await Task.sleep(for: .milliseconds(500))

        func capture(_ name: String, attach: Bool = true) throws -> Data {
            host.view.layoutIfNeeded()
            let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
                window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
            }
            if attach {
                let attachment = XCTAttachment(image: image)
                attachment.name = name
                attachment.lifetime = .keepAlways
                add(attachment)
            }
            // The existing conventional button is 24 pt from the left/bottom.
            let scale = image.scale
            let crop = CGRect(x: 30, y: window.bounds.height - 66, width: 36, height: 36)
                .applying(CGAffineTransform(scaleX: scale, y: scale))
            let cg = try XCTUnwrap(image.cgImage?.cropping(to: crop))
            return try XCTUnwrap(UIImage(cgImage: cg).pngData())
        }
        let initial = try capture("Clock-screen-initial")
        model.updateDialRotation(-15)
        try await Task.sleep(for: .milliseconds(150))
        let forward = try capture("Clock-screen-forward")
        XCTAssertNotEqual(initial, forward, "The real screen clock must redraw when the wheel advances")
        model.updateDialRotation(15)
        try await Task.sleep(for: .milliseconds(150))
        let backward = try capture("Clock-screen-backward")
        XCTAssertNotEqual(forward, backward)
        model.endDialDrag(currentRotation: 15, predictedRotation: 45)
        try await Task.sleep(for: .milliseconds(250))
        let inertia = try capture("Clock-screen-inertia")
        XCTAssertNotEqual(backward, inertia)
        model.cancelDialDrag()
        try await Task.sleep(for: .milliseconds(150))
        let beforePrimary = try capture("Clock-screen-before-primary-change")
        let frozenInstant = model.selectedInstant
        store.cities.reverse()
        let deadline = ContinuousClock.now.advanced(by: .seconds(3))
        while try capture("Clock-screen-primary-pending", attach: false) == beforePrimary,
              ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(50))
        }
        let primary = try capture("Clock-screen-primary-changed")
        XCTAssertNotEqual(beforePrimary, primary)
        XCTAssertEqual(model.selectedInstant, frozenInstant)
        model.resetToNow()
        try await Task.sleep(for: .milliseconds(150))
        XCTAssertNotEqual(primary, try capture("Clock-screen-now"))
        XCTAssertEqual(model.selectedInstant, model.now)
    }

    func testSecondsHandHasTheStraightFigmaShaft() throws {
        let renderer = ImageRenderer(content: AnalogClockSwitcherIcon(
            instant: instant("2026-10-29T10:08:00Z"), timeZone: .gmt)
            .environment(\.appTheme, .light))
        renderer.scale = 3
        let cg = try XCTUnwrap(renderer.cgImage)
        var pixels = [UInt8](repeating: 0, count: 108 * 108 * 4)
        let context = try XCTUnwrap(CGContext(data: &pixels, width: 108, height: 108,
            bitsPerComponent: 8, bytesPerRow: 108 * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(cg, in: CGRect(x: 0, y: 0, width: 108, height: 108))
        // At y=8 the shaft is exactly 1 pt wide, centered at x=18.
        for x in [53, 54] {
            let offset = (24 * 108 + x) * 4
            XCTAssertGreaterThan(pixels[offset], 245)
            XCTAssertLessThan(pixels[offset + 1], 80)
            XCTAssertLessThan(pixels[offset + 2], 10)
        }
    }

}
