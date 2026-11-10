import XCTest
import SwiftUI
import MetalKit
@testable import MapHarness

@MainActor final class MapVisualRedesignTests: XCTestCase {
    private let instant = Date(timeIntervalSince1970: 1793235600)
    private let cities = [
        City(name: "Same name", timeZoneID: "Asia/Kolkata", canonicalID: "city:fixture-primary-A", latitude: 28.61, longitude: 77.2),
        City(name: "Same name", timeZoneID: "Asia/Kolkata", canonicalID: "city:fixture-primary-B", latitude: 28.62, longitude: 77.3),
        City(name: "Bangkok", timeZoneID: "Asia/Bangkok", canonicalID: "city:fixture-other", latitude: 13.7563, longitude: 100.5018)]

    private func update(_ map: WorldMapScrollView, primary: String?) {
        map.updateMarkers(cities, at: instant, timeFormatPreference: "twentyFourHour", localeIdentifier: "en_US", primaryCityID: primary)
    }

    func testExactPinSizesLiveIdentityGroupingAndHitRegions() throws {
        let map = WorldMapScrollView(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        map.updatePosition(0.72) { _ in }; update(map, primary: nil); map.layoutIfNeeded()
        let groups = map.sharedLabels.map(\.cityIDs)
        XCTAssertTrue(groups.contains(["city:fixture-primary-A", "city:fixture-primary-B"]))
        let views = map.markers.map(ObjectIdentifier.init)
        for primary in ["city:fixture-primary-A", "city:fixture-primary-B", "missing", "city:fixture-primary-A"] {
            update(map, primary: primary)
            XCTAssertEqual(map.markers.map(ObjectIdentifier.init), views)
            XCTAssertEqual(map.sharedLabels.map(\.cityIDs), groups)
            XCTAssertEqual(map.markers.filter(\.isPrimary).map(\.cityID), primary == "missing" ? [] : [primary])
            for (index, marker) in map.markers.enumerated() {
                let dot = marker.convert(marker.dotBounds, to: map.mapCanvas)
                XCTAssertEqual(dot.width, marker.isPrimary ? 20 : 12, accuracy: 1e-6)
                XCTAssertEqual(dot, map.hitDots[index].bounds)
                XCTAssertEqual(dot.midX, marker.normalizedPoint.x * map.mapCanvas.bounds.width, accuracy: 1e-6)
                XCTAssertEqual(dot.midY, marker.normalizedPoint.y * map.mapCanvas.bounds.height, accuracy: 1e-6)
                let image = try XCTUnwrap(marker.indicator.image)
                XCTAssertEqual(image.size.width, marker.isPrimary ? 36 : 28)
                let light = image.resolvedAsset(with: UITraitCollection(userInterfaceStyle: .light))
                let dark = image.resolvedAsset(with: UITraitCollection(userInterfaceStyle: .dark))
                XCTAssertEqual(light.pngData(), dark.pngData())
            }
            let grouped = try XCTUnwrap(map.sharedLabels.first)
            XCTAssertEqual(grouped.cityIDs, ["city:fixture-primary-A", "city:fixture-primary-B"])
            XCTAssertEqual(map.hitLabels.first { $0.cityIDs.count == 2 }?.cityIDs, grouped.cityIDs)
            XCTAssertTrue(map.markerTap.delegate === map.markerTapDelegate)
        }
        // A larger ring must be a real hit target, including outside the old dot.
        update(map, primary: "city:fixture-other")
        let target = try XCTUnwrap(map.hitDots.last)
        XCTAssertEqual(WorldMapHitTesting.cityIDs(at: CGPoint(x: target.bounds.maxX - 1, y: target.bounds.midY),
                                                  dots: map.hitDots, labels: map.hitLabels, period: map.mapCanvas.bounds.width), ["city:fixture-other"])
    }

    func testObservedPrimaryChangesWithFrozenClockAndUnresolvedFirstCity() async throws {
        let unresolved = City(name: "Unresolved", timeZoneID: "Etc/UTC", canonicalID: "city:fixture-missing-coordinate")
        let data = try JSONEncoder().encode([unresolved] + cities)
        let store = CityStore(storage: .init(read: { _ in data }, write: { _, _ in }, sharedDefaults: { _ in nil }, reloadWidgets: {}))
        let model = TimeDialViewModel(); model.tickerTask?.cancel(); model.beginDialDrag(); model.baseTime = instant
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        let host = UIHostingController(rootView: WorldMapObservedContent(viewModel: model, cityStore: store,
            viewportSize: CGSize(width: 393, height: 852), horizontalPosition: .constant(0.72)))
        window.rootViewController = host; window.makeKeyAndVisible()
        defer { window.isHidden = true; previous?.makeKeyAndVisible() }
        func find(_ view: UIView) -> WorldMapScrollView? {
            if let map = view as? WorldMapScrollView { return map }
            return view.subviews.lazy.compactMap(find).first
        }
        try await Task.sleep(for: .milliseconds(200))
        let map = try XCTUnwrap(find(host.view))
        XCTAssertEqual(map.markers.count, 3)
        XCTAssertTrue(map.markers.allSatisfy { !$0.isPrimary }, "Visible array position must never imply Primary")
        let frozen = model.selectedInstant
        store.cities.removeFirst()
        try await Task.sleep(for: .milliseconds(200))
        XCTAssertEqual(map.markers.filter(\.isPrimary).map(\.cityID), ["city:fixture-primary-A"])
        store.cities.swapAt(0, 1)
        try await Task.sleep(for: .milliseconds(200))
        XCTAssertEqual(map.markers.filter(\.isPrimary).map(\.cityID), ["city:fixture-primary-B"])
        XCTAssertEqual(model.selectedInstant, frozen)
        XCTAssertTrue(find(host.view) === map)
    }

    func testGroupedPrimaryChooserKeepsAllCitiesAccessible() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene); let host = UIViewController()
        window.rootViewController = host; window.makeKeyAndVisible()
        defer { window.isHidden = true; previous?.makeKeyAndVisible() }
        let map = WorldMapScrollView(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        host.view.addSubview(map); map.updatePosition(0.72) { _ in }
        update(map, primary: cities[1].id); map.layoutIfNeeded()
        let ids = try XCTUnwrap(map.sharedLabels.first?.cityIDs)
        func chooseOnce() async throws {
            XCTAssertTrue(map.activateCities(ids))
            try await Task.sleep(for: .milliseconds(400))
            let chooser = try XCTUnwrap(host.presentedViewController as? UIAlertController)
            XCTAssertEqual(chooser.actions.count, ids.count + 1)
            XCTAssertNotEqual(chooser.actions[0].title, chooser.actions[1].title)
            await withCheckedContinuation { continuation in
                chooser.dismiss(animated: false) { continuation.resume() }
            }
            XCTAssertNil(host.presentedViewController)
        }
        try await chooseOnce()
        XCTAssertTrue(map.isScrollEnabled)
        map.contentOffset.x += 30; map.layoutIfNeeded()
        var selected: [City.ID] = []
        map.onCitiesSelected = { selected = $0 }
        XCTAssertTrue(map.activateCities([cities[1].id]))
        XCTAssertEqual(selected, [cities[1].id])
    }

    func testStandalonePrimaryAppearanceScreenshots() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene); let parent = UIViewController()
        window.rootViewController = parent; window.makeKeyAndVisible()
        defer { window.isHidden = true; previous?.makeKeyAndVisible() }
        let map = WorldMapScrollView(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        parent.view.addSubview(map); map.updatePosition(0.72) { _ in }
        let selected = [cities[0], cities[2]]
        map.updateNightLights(selected); map.updateIllumination(at: instant)
        for dark in [false, true] {
            window.overrideUserInterfaceStyle = dark ? .dark : .light
            map.updateMarkers(selected, at: instant, timeFormatPreference: "twentyFourHour", localeIdentifier: "en_US",
                              primaryCityID: selected[0].id)
            map.layoutIfNeeded(); try await Task.sleep(for: .milliseconds(150))
            XCTAssertTrue(map.sharedLabels.isEmpty)
            XCTAssertEqual(map.markers.filter(\.isPrimary).map(\.cityID), [selected[0].id])
            let screenshot = UIGraphicsImageRenderer(bounds: map.bounds).image { _ in
                XCTAssertTrue(map.drawHierarchy(in: map.bounds, afterScreenUpdates: true))
            }
            let a = XCTAttachment(image: screenshot); a.name = "primary-standalone-\(dark ? "dark" : "light")"
            a.lifetime = .keepAlways; add(a)
        }
    }

    func testManifestDistributionAndNoIdleInvalidation() async throws {
        XCTAssertEqual(DecorativeCityIDs.catalogIDs.count, 50)
        XCTAssertEqual(Set(DecorativeCityIDs.catalogIDs).count, 50)
        XCTAssertTrue(Set(DecorativeCityIDs.catalogIDs).isSubset(of: Set(OriginalDecorativeCityIDs.catalogIDs)))
        let lights = NightCityLights().lights(savedCities: [])
        XCTAssertEqual(lights.count, 50)
        let longitudes = lights.map(\.coordinate.longitude)
        XCTAssertLessThan(longitudes.min()!, -120); XCTAssertGreaterThan(longitudes.max()!, 170)
        XCTAssertGreaterThanOrEqual(lights.filter { $0.coordinate.latitude < 0 }.count, 12)
        let regions: [Set<String>] = [
            ["vancouver-ca", "los-angeles-us", "denver-us", "chicago-us", "toronto-ca", "new-york-us", "miami-us", "mexico-city-mx"],
            ["bogota-co", "lima-pe", "sao-paulo-br", "rio-br", "buenos-aires-ar", "santiago-cl"],
            ["london-gb", "paris-fr", "madrid-es", "rome-it", "berlin-de", "moscow-ru", "istanbul-tr"],
            ["casablanca-ma", "lagos-ng", "cairo-eg", "addis-ababa-et", "nairobi-ke", "johannesburg-za", "cape-town-za"],
            ["perth-au", "melbourne-au", "sydney-au", "auckland-nz", "suva-fj"]]
        XCTAssertEqual(regions.map { $0.intersection(DecorativeCityIDs.catalogIDs).count }, [8, 6, 7, 7, 5])
        let renderer = try NightRenderer()
        XCTAssertNotNil(renderer.lightPipeline); XCTAssertNotNil(renderer.lightTexture)
        XCTAssertEqual(renderer.lightTexture?.width, 42)
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene); let parent = UIViewController()
        window.rootViewController = parent; window.makeKeyAndVisible()
        defer { window.isHidden = true; previous?.makeKeyAndVisible() }
        let overlay = DayNightOverlay(renderer: renderer, date: instant)
        parent.view.addSubview(overlay)
        overlay.frame = CGRect(x: 0, y: 0, width: 393, height: 852); overlay.layoutIfNeeded()
        overlay.updateLights(lights)
        overlay.update(date: instant, origin: .zero, span: SIMD2(1, 1), style: NightStyle())
        try await Task.sleep(for: .milliseconds(300))
        XCTAssertFalse(overlay.needsRender, "Initial visible draw completed")
        XCTAssertTrue(overlay.lightSlots.contains { $0.buffer != nil })
        let revision = overlay.lightRevision
        let buffers = overlay.lightSlots.map { $0.buffer.map(ObjectIdentifier.init) }
        for _ in 0..<100 {
            overlay.updateLights(lights)
            overlay.update(date: instant, origin: .zero, span: SIMD2(1, 1), style: NightStyle())
        }
        try await Task.sleep(for: .milliseconds(300))
        XCTAssertFalse(overlay.needsRender)
        XCTAssertEqual(overlay.lightRevision, revision)
        XCTAssertTrue(overlay.isPaused); XCTAssertTrue(overlay.enableSetNeedsDisplay)
        XCTAssertEqual(overlay.lightSlots.map { $0.buffer.map(ObjectIdentifier.init) }, buffers)
        XCTAssertEqual(NightCityLights.visibility(elevation: -3), 0)
        XCTAssertEqual(NightCityLights.visibility(elevation: -6), 0.5)
        XCTAssertEqual(NightCityLights.visibility(elevation: -9), 1)
    }

    func testPrimaryAndNightTwilightDayScreenshotsAcrossProfiles() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene); let parent = UIViewController()
        window.rootViewController = parent; window.makeKeyAndVisible()
        defer { window.isHidden = true; previous?.makeKeyAndVisible() }
        let map = WorldMapScrollView(frame: CGRect(x: 0, y: 0, width: 393, height: 852)); parent.view.addSubview(map)
        map.updatePosition(0.72) { _ in }; map.updateNightLights(cities)
        let profiles: [(String, WorldMapGeometryProfile, CGSize)] = [
            ("iphone", .conventional, CGSize(width: 393, height: 852)),
            ("outer", .duoOuter, CGSize(width: 382, height: 678)),
            ("open-landscape", .duoInner, CGSize(width: 527, height: 669)),
            ("partial-landscape", .duoInner, CGSize(width: 455.667, height: 669)),
            ("open-portrait", .duoInnerPortrait, CGSize(width: 669, height: 476)),
            ("partial-portrait", .duoInnerPortrait, CGSize(width: 669, height: 407)),
            ("split", .duoOuter, CGSize(width: 375, height: 669))]
        let formatter = ISO8601DateFormatter()
        // Bangkok/Delhi sector: daylight, sunset/twilight, full night.
        for (phase, time) in [("day", "2026-11-09T06:00:00Z"), ("twilight", "2026-11-09T11:10:00Z"), ("night", "2026-11-09T18:00:00Z")] {
            let date = formatter.date(from: time)!
            for dark in [false, true] {
                window.overrideUserInterfaceStyle = dark ? .dark : .light
                for (name, profile, size) in profiles {
                    map.frame.size = size; map.updatePresentation(profile: profile, visible: true)
                    map.updateIllumination(at: date)
                    map.updateMarkers(cities, at: date, timeFormatPreference: "twentyFourHour", localeIdentifier: "en_US", primaryCityID: "city:fixture-primary-A")
                    map.layoutIfNeeded(); try await Task.sleep(for: .milliseconds(80))
                    for marker in map.markers {
                        XCTAssertEqual(marker.convert(marker.dotBounds, to: map).width, marker.isPrimary ? 20 : 12, accuracy: 1e-6)
                    }
                    let image = UIGraphicsImageRenderer(bounds: map.bounds).image { _ in
                        XCTAssertTrue(map.drawHierarchy(in: map.bounds, afterScreenUpdates: true))
                    }
                    let a = XCTAttachment(image: image); a.name = "redesign-\(name)-\(dark ? "dark" : "light")-\(phase)"; a.lifetime = .keepAlways; add(a)
                }
            }
        }
    }
}

private extension UIImage {
    func resolvedAsset(with traits: UITraitCollection) -> UIImage { imageAsset?.image(with: traits) ?? self }
}
