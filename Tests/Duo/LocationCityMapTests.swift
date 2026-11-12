import XCTest
import SwiftUI
import CoreLocation
@testable import MapHarness

@MainActor final class LocationCityMapTests: XCTestCase {
    // Controlled fixtures, not coordinates captured from the TestFlight report.
    private let resolved = CLLocationCoordinate2D(latitude: 13.7449, longitude: 100.5332)
    private let device = CLLocationCoordinate2D(latitude: 13.7466, longitude: 100.5393)
    private let instant = Date(timeIntervalSince1970: 1735736400)

    private func locationItem(resolved: CLLocationCoordinate2D? = nil,
                              device: CLLocationCoordinate2D? = nil) -> CitySearchItem {
        CurrentLocationCityProvider.cityItem(
            city: "Pathum Wan District", country: "Thailand", timeZoneIdentifier: "Asia/Bangkok",
            resolvedCoordinate: resolved ?? self.resolved, deviceCoordinate: device ?? self.device)
    }

    func testNonCatalogLocationRetainsResolvedCoordinateThroughCityAndJSON() throws {
        let item = locationItem()
        let oldItem = CitySearchItem(id: item.id, city: item.city, country: item.country,
                                    timeZoneIdentifier: item.timeZoneIdentifier, aliases: [])
        let resolver = LegacyCityCoordinateResolver()
        XCTAssertNil(oldItem.asCity.latitude)
        XCTAssertNil(resolver.coordinate(for: oldItem.asCity), "Reproduces the old missing marker")
        let city = item.asCity
        XCTAssertEqual(city.id, oldItem.canonicalIdentity, "Geography cannot change location identity")
        XCTAssertEqual(city.latitude, resolved.latitude)
        XCTAssertEqual(city.longitude, resolved.longitude)
        XCTAssertEqual(city.timeZone.secondsFromGMT(for: instant), 7 * 3600)
        let reloaded = try JSONDecoder().decode(City.self, from: JSONEncoder().encode(city))
        XCTAssertEqual(reloaded, city)
        XCTAssertEqual(resolver.coordinate(for: reloaded), .init(latitude: resolved.latitude, longitude: resolved.longitude))
        print("LOCATION TRACE id=\(city.id) device=\(device.latitude),\(device.longitude) resolved=\(resolved.latitude),\(resolved.longitude) oldSaved=nil,nil oldCandidate=nil correctedSaved=\(String(describing: city.latitude)),\(String(describing: city.longitude)) reloaded=\(String(describing: reloaded.latitude)),\(String(describing: reloaded.longitude))")
    }

    func testCoordinateFallbackValidationAndCatalogSettlementPrecedence() throws {
        for invalid in [CLLocationCoordinate2D(latitude: 91, longitude: 181),
                        CLLocationCoordinate2D(latitude: .nan, longitude: 100),
                        CLLocationCoordinate2D(latitude: 13, longitude: .infinity)] {
            let fallback = locationItem(resolved: invalid).asCity
            XCTAssertEqual(fallback.latitude, device.latitude)
            XCTAssertEqual(fallback.longitude, device.longitude)
            let unresolved = locationItem(resolved: invalid, device: invalid).asCity
            XCTAssertNil(unresolved.latitude); XCTAssertNil(unresolved.longitude)
            XCTAssertNil(LegacyCityCoordinateResolver().coordinate(for: unresolved))
        }
        let zero = locationItem(resolved: CLLocationCoordinate2D(latitude: 0, longitude: 0)).asCity
        XCTAssertEqual(zero.latitude, 0); XCTAssertEqual(zero.longitude, 0)
        let catalog = try XCTUnwrap(CitySearchProvider.shared.canonicalItemForCurrentLocation(
            city: "Bangkok", country: "Thailand", timeZoneIdentifier: "Asia/Bangkok"))
        let locatedCatalog = CurrentLocationCityProvider.cityItem(
            city: "Bangkok", country: "Thailand", timeZoneIdentifier: "Asia/Bangkok",
            resolvedCoordinate: resolved, deviceCoordinate: device)
        XCTAssertEqual(locatedCatalog.asCity, catalog.asCity)
        XCTAssertNotNil(catalog.asCity.latitude)
        XCTAssertNotEqual(catalog.asCity.latitude, device.latitude)
        let manual = CitySearchItem(id: "manual-no-geography", city: "Unresolved Place", country: "Thailand",
                                    timeZoneIdentifier: "Asia/Bangkok", aliases: []).asCity
        XCTAssertNil(manual.latitude, "Device coordinates never leak into manual additions")
    }

    func testSmallManualSearchCityKeepsItsOwnResolvedGeography() throws {
        let name = "Ban Mae Kampong"
        XCTAssertNil(CitySearchProvider.shared.canonicalItemForCurrentLocation(
            city: name, country: "Thailand", timeZoneIdentifier: "Asia/Bangkok"))
        let selected = CitySearchItem(
            id: "mapkit-small-settlement", city: name, country: "Thailand",
            timeZoneIdentifier: "Asia/Bangkok", aliases: [],
            geographicalEvidence: .init(
                placeIdentifier: nil, alternatePlaceIdentifiers: nil, originalName: name,
                cityName: name, countryCode: "TH",
                coordinates: .init(latitude: 18.865, longitude: 99.351),
                cityWithContext: nil, cityWithFullContext: nil, fullAddress: nil,
                shortAddress: nil, pointOfInterestCategory: nil))
        let city = selected.asCity
        XCTAssertEqual(city.latitude, 18.865); XCTAssertEqual(city.longitude, 99.351)
        XCTAssertNotEqual(city.latitude, device.latitude)
        let saved = try JSONDecoder().decode(City.self, from: JSONEncoder().encode(city))
        let map = makeMap([locationItem().asCity, saved])
        XCTAssertEqual(map.markers.map(\.cityID), [locationItem().canonicalIdentity, city.id])
        XCTAssertEqual(map.markers.last?.normalizedPoint,
                       WorldMapProjection.normalizedPoint(.init(latitude: 18.865, longitude: 99.351)))
    }

    func testFileRelaunchAddReorderDeletePreserveMarkersAndLocationIdentity() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let manager = LocationMapFileManager(root: root)
        let storage = CityStore.Storage(sharedDefaults: { _ in nil }, reloadWidgets: {})
        let location = locationItem()
        let other = try XCTUnwrap(CitySearchProvider.shared.canonicalItemForCurrentLocation(
            city: "Bangkok", country: "Thailand", timeZoneIdentifier: "Asia/Bangkok")).asCity
        for existingList in [false, true] {
            let store = CityStore(fileManager: manager, storage: storage)
            store.cities = existingList ? [other] : []
            store.cities.append(location.asCity)
            XCTAssertTrue(store.save())
            var reopened = CityStore(fileManager: manager, storage: storage)
            XCTAssertEqual(reopened.cities, store.cities)
            if !existingList { reopened.cities.append(other) }
            for _ in 0..<4 {
                reopened.cities.reverse()
                let expected = reopened.cities
                reopened = CityStore(fileManager: manager, storage: storage)
                XCTAssertEqual(reopened.cities, expected)
                let map = makeMap(reopened.cities)
                XCTAssertEqual(map.markers.map(\.cityID), expected.map(\.id))
                XCTAssertEqual(map.markers.filter(\.isPrimary).map(\.cityID), [expected[0].id])
                let list = CityListReorderViewController()
                list.loadViewIfNeeded()
                list.apply(cities: expected, selectedInstant: instant, userCurrentLocationItem: location,
                           cityViewPreference: .basic, topInset: 0, bottomInset: 0,
                           cardBackgroundColor: AppTheme.light.surfaceCard)
                XCTAssertEqual(expected[try XCTUnwrap(list.currentLocationMatchIndex())].id, location.canonicalIdentity)
                XCTAssertEqual(expected.filter { $0.id == location.canonicalIdentity }.count, 1)
            }
            reopened.cities.removeAll { $0.id == other.id }
            let afterDelete = CityStore(fileManager: manager, storage: storage)
            XCTAssertEqual(afterDelete.cities, [location.asCity])
            XCTAssertEqual(makeMap(afterDelete.cities).markers.map(\.cityID), [location.canonicalIdentity])
        }
    }

    private func makeMap(_ cities: [City], profile: WorldMapGeometryProfile = .conventional,
                         size: CGSize = CGSize(width: 393, height: 852)) -> WorldMapScrollView {
        let map = WorldMapScrollView(frame: CGRect(origin: .zero, size: size))
        map.updatePresentation(profile: profile, visible: true)
        map.updatePosition((resolved.longitude + 180) / 360) { _ in }
        update(map, cities)
        map.layoutIfNeeded()
        return map
    }

    private func update(_ map: WorldMapScrollView, _ cities: [City]) {
        map.updateMarkers(cities, at: instant, timeFormatPreference: "twentyFourHour",
                          localeIdentifier: "en_US", primaryCityID: cities.primaryCity?.id)
    }

    private func visiblePoint(_ rect: CGRect, in map: WorldMapScrollView) -> CGPoint {
        let nearest = WorldMapPeriodic.nearest(rect, to: map.bounds.midX, period: map.mapCanvas.bounds.width)
        return CGPoint(x: nearest.midX, y: nearest.midY + map.repeatedCanvas.frame.minY)
    }

    func testLocationMarkerRenderingSelectionGroupingAndVisibilityAcrossProfiles() throws {
        let city = locationItem().asCity
        let neighbor = City(name: "Nearby fixture", timeZoneID: city.timeZoneID, canonicalID: "city:nearby-fixture",
                            latitude: resolved.latitude, longitude: resolved.longitude + 0.01)
        for (profile, size) in [(WorldMapGeometryProfile.conventional, CGSize(width: 393, height: 852)),
                                (.duoOuter, CGSize(width: 382, height: 678)),
                                (.duoInner, CGSize(width: 527, height: 669)),
                                (.duoInnerPortrait, CGSize(width: 669, height: 476))] {
            for appearance in [UIUserInterfaceStyle.light, .dark] {
                let map = makeMap([], profile: profile, size: size)
                map.overrideUserInterfaceStyle = appearance
                update(map, [city]); map.layoutIfNeeded()
                let marker = try XCTUnwrap(map.markers.first)
                XCTAssertEqual(map.markers.count, 1)
                XCTAssertTrue(marker.isPrimary)
                XCTAssertEqual(marker.displayName, city.name)
                XCTAssertEqual(marker.displayedTime, CityTimeFormatter.formatTime(instant, in: city.timeZone))
                XCTAssertEqual(marker.normalizedPoint,
                               WorldMapProjection.normalizedPoint(.init(latitude: resolved.latitude, longitude: resolved.longitude)))
                var selected: [City.ID] = []
                map.onCitiesSelected = { selected = $0 }
                for target in [try XCTUnwrap(map.hitDots.first), try XCTUnwrap(map.hitLabels.first)] {
                    let point = visiblePoint(target.bounds, in: map)
                    XCTAssertTrue(map.bounds.contains(point), "Location marker/label lies in the visible viewport")
                    let ids = map.cityIDs(at: point)
                    XCTAssertEqual(ids, [city.id]); XCTAssertTrue(map.activateCities(ids))
                    XCTAssertEqual(selected, [city.id], "Existing City Details callback receives saved identity")
                }
                let image = UIGraphicsImageRenderer(size: size).image { context in
                    context.cgContext.translateBy(x: -map.bounds.minX, y: -map.bounds.minY)
                    map.layer.render(in: context.cgContext)
                }
                let attachment = XCTAttachment(image: image)
                attachment.name = "Location-\(profile)-\(appearance == .dark ? "dark" : "light")"
                attachment.lifetime = .keepAlways; add(attachment)
                for _ in 0..<5 {
                    map.updatePresentation(profile: profile, visible: false)
                    XCTAssertFalse(map.activateCities([city.id]))
                    map.updatePresentation(profile: profile, visible: true)
                    update(map, [neighbor, city]); map.layoutIfNeeded()
                    XCTAssertEqual(map.markers.count, 2)
                    XCTAssertFalse(try XCTUnwrap(map.markers.first { $0.cityID == city.id }).isPrimary)
                    XCTAssertEqual(map.sharedLabels.first?.cityIDs, [neighbor.id, city.id])
                    update(map, [city]); map.layoutIfNeeded()
                    XCTAssertTrue(map.sharedLabels.isEmpty)
                    XCTAssertTrue(map.activateCities([city.id]))
                    XCTAssertEqual(selected, [city.id])
                }
            }
        }
    }

    func testRealScreenLocationMarkerOpensCityDetails() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = CityStore(fileManager: LocationMapFileManager(root: root),
                              storage: .init(sharedDefaults: { _ in nil }, reloadWidgets: {}))
        let model = TimeDialViewModel()
        model.tickerTask?.cancel(); model.beginDialDrag(); model.baseTime = instant
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        let screen = TimeDialScreen(viewModel: model, cityPresentation: .map)
        let host = UIHostingController(rootView: screen.environmentObject(store).environment(\.appTheme, .light))
        window.rootViewController = host; window.makeKeyAndVisible()
        defer { window.isHidden = true; previous?.makeKeyAndVisible() }
        store.cities.append(locationItem().asCity)
        func findMap(_ view: UIView) -> WorldMapScrollView? {
            if let map = view as? WorldMapScrollView { return map }
            return view.subviews.lazy.compactMap(findMap).first
        }
        try await Task.sleep(for: .milliseconds(500))
        let map = try XCTUnwrap(findMap(host.view))
        XCTAssertEqual(map.markers.map(\.cityID), [locationItem().canonicalIdentity])
        map.updatePosition((resolved.longitude + 180) / 360) { _ in }; map.layoutIfNeeded()
        let dot = try XCTUnwrap(map.hitDots.first)
        let ids = map.cityIDs(at: visiblePoint(dot.bounds, in: map))
        XCTAssertEqual(ids, [locationItem().canonicalIdentity])
        XCTAssertTrue(map.activateCities(ids))
        try await Task.sleep(for: .milliseconds(700))
        XCTAssertNotNil(host.presentedViewController, "Actual screen presents City Details from its map callback")
        let attachment = XCTAttachment(image: UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        })
        attachment.name = "Location-City-Details-real-screen"; attachment.lifetime = .keepAlways; add(attachment)
        if let presented = host.presentedViewController {
            await withCheckedContinuation { continuation in
                presented.dismiss(animated: false) { continuation.resume() }
            }
        }
    }

    func testObservedMapReceivesCoordinateOnlyRepairAndListChanges() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = CityStore(fileManager: LocationMapFileManager(root: root),
                              storage: .init(sharedDefaults: { _ in nil }, reloadWidgets: {}))
        let model = TimeDialViewModel()
        let city = locationItem().asCity
        let host = UIHostingController(rootView: WorldMapObservedContent(
            viewModel: model, cityStore: store, viewportSize: CGSize(width: 393, height: 852),
            horizontalPosition: .constant((resolved.longitude + 180) / 360)))
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        window.rootViewController = host; window.makeKeyAndVisible()
        defer { window.isHidden = true; previous?.makeKeyAndVisible() }
        try await Task.sleep(for: .milliseconds(100))
        func findMap(_ view: UIView) -> WorldMapScrollView? {
            if let map = view as? WorldMapScrollView { return map }
            return view.subviews.compactMap(findMap).first
        }
        host.view.layoutIfNeeded()
        let map = try XCTUnwrap(findMap(host.view))
        // A saved pre-fix city has the same ID, name and zone but no coordinate.
        store.cities = [City(canonicalCity: city.canonicalCity)]
        try await Task.sleep(for: .milliseconds(100)); host.view.layoutIfNeeded()
        XCTAssertTrue(map.markers.isEmpty)
        store.cities = [city]
        try await Task.sleep(for: .milliseconds(100)); host.view.layoutIfNeeded()
        XCTAssertEqual(map.markers.map(\.cityID), [city.id])
        store.cities = []
        try await Task.sleep(for: .milliseconds(100)); host.view.layoutIfNeeded()
        XCTAssertTrue(map.markers.isEmpty)
    }
}

private final class LocationMapFileManager: FileManager, @unchecked Sendable {
    let root: URL
    init(root: URL) { self.root = root; super.init() }
    override func url(for directory: FileManager.SearchPathDirectory, in domain: FileManager.SearchPathDomainMask,
                      appropriateFor url: URL?, create shouldCreate: Bool) throws -> URL {
        if directory == .applicationSupportDirectory { return root }
        return try super.url(for: directory, in: domain, appropriateFor: url, create: shouldCreate)
    }
    override func containerURL(forSecurityApplicationGroupIdentifier groupIdentifier: String) -> URL? { nil }
}
