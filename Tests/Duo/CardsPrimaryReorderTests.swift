import XCTest
import SwiftUI
@testable import MapHarness

@MainActor final class CardsPrimaryReorderTests: XCTestCase {
    private let instant = Date(timeIntervalSince1970: 1735736400)
    private var cities: [City] {
        [City(name: "Bangkok", timeZoneID: "Asia/Bangkok", canonicalID: "city:primary-bangkok", latitude: 13.75, longitude: 100.5),
         City(name: "London", timeZoneID: "Europe/London", canonicalID: "city:primary-london", latitude: 51.5, longitude: -0.12),
         City(name: "Los Angeles", timeZoneID: "America/Los_Angeles", canonicalID: "city:primary-la", latitude: 34.05, longitude: -118.24),
         City(name: "Sydney", timeZoneID: "Australia/Sydney", canonicalID: "city:primary-sydney", latitude: -33.86, longitude: 151.2),
         City(name: "Tokyo", timeZoneID: "Asia/Tokyo", canonicalID: "city:primary-tokyo", latitude: 35.68, longitude: 139.69)]
    }
    private func apply(_ controller: CityListReorderViewController, _ cities: [City], mode: CityViewPreference = .cards) {
        controller.apply(cities: cities, selectedInstant: instant, userCurrentLocationItem: nil,
                         cityViewPreference: mode, topInset: 20, bottomInset: 0,
                         cardBackgroundColor: AppTheme.light.surfaceCard)
        controller.view.layoutIfNeeded(); controller.collectionView.layoutIfNeeded()
    }

    func testPreviouslySavedCardsPrimaryFlagCannotOverrideOrder() throws {
        var records = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(cities)) as? [[String: Any]])
        records[4]["isPrimary"] = true
        records[0]["isPrimary"] = false
        let disk = PrimaryTestDisk(try JSONSerialization.data(withJSONObject: records))
        let store = CityStore(storage: disk.storage)
        XCTAssertEqual(store.cities.map(\.id), cities.map(\.id))
        XCTAssertEqual(store.cities.primaryCity?.id, cities[0].id)
        store.cities.swapAt(0, 1)
        let relaunched = CityStore(storage: disk.storage)
        XCTAssertEqual(relaunched.cities.primaryCity?.id, cities[1].id)
        let saved = try XCTUnwrap(JSONSerialization.jsonObject(with: disk.data) as? [[String: Any]])
        XCTAssertTrue(saved.allSatisfy { $0["isPrimary"] == nil })
        XCTAssertEqual(relaunched.cities.count, cities.count)
    }

    func testSharedOrderForOneTwoOddEvenAndRapidMoves() async throws {
        for count in [1, 2, 5, 6, 13] {
            let initial = (0..<count).map { City(name: "City \($0)", timeZoneID: "Europe/Paris", canonicalID: "city:count-\($0)") }
            let disk = PrimaryTestDisk(try JSONEncoder().encode(initial))
            let store = CityStore(storage: disk.storage)
            let controller = CityListReorderViewController()
            controller.loadViewIfNeeded()
            controller.view.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
            controller.onCitiesChanged = { store.cities = $0 }
            for mode: CityViewPreference in [.cards, .basic, .compact, .cards] {
                apply(controller, store.cities, mode: mode)
                var expected = store.cities
                for (source, destination) in [(count - 1, 0), (0, count - 1), (min(1, count - 1), 0)] {
                    let moved = expected.remove(at: source); expected.insert(moved, at: destination)
                    controller.collectionView(controller.collectionView, moveItemAt: IndexPath(item: source, section: 0),
                                              to: IndexPath(item: destination, section: 0))
                    XCTAssertEqual(controller.citiesLocal.primaryCity?.id, expected.first?.id)
                }
                try await Task.sleep(for: .milliseconds(50))
                XCTAssertEqual(store.cities, expected)
                XCTAssertEqual(Set(store.cities.map(\.id)).count, count)
                let relaunched = CityStore(storage: disk.storage)
                XCTAssertEqual(relaunched.cities, expected)
                XCTAssertEqual(relaunched.cities.primaryCity?.id, expected.first?.id)
            }
        }
    }

    func testAtomicFileReloadAfterReorderAndPrimaryDeletion() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let manager = PrimaryTestFileManager(root: root)
        var storage = CityStore.Storage()
        storage.sharedDefaults = { _ in nil }; storage.reloadWidgets = {}
        let store = CityStore(fileManager: manager, storage: storage)
        store.cities = cities
        let controller = CityListReorderViewController()
        controller.loadViewIfNeeded()
        controller.onCitiesChanged = { store.cities = $0 }
        apply(controller, store.cities)
        controller.collectionView(controller.collectionView, moveItemAt: IndexPath(item: 4, section: 0),
                                  to: IndexPath(item: 0, section: 0))
        try await Task.sleep(for: .milliseconds(50))
        let reopened = CityStore(fileManager: manager, storage: storage)
        XCTAssertEqual(reopened.cities, store.cities)
        XCTAssertEqual(reopened.cities.primaryCity?.id, cities[4].id)
        XCTAssertEqual(try JSONDecoder().decode([City].self, from: Data(contentsOf: root.appendingPathComponent("cities.json"))), store.cities)
        reopened.cities.removeFirst()
        XCTAssertEqual(CityStore(fileManager: manager, storage: storage).cities.primaryCity?.id, cities[0].id)
    }

    func testLiveReorderUpdatesIndicatorsDifferencesMapAndPersistsAcrossModes() async throws {
        let defaults = UserDefaults.standard
        let oldMode = defaults.object(forKey: CityViewPreference.storageKey)
        defer { defaults.set(oldMode, forKey: CityViewPreference.storageKey) }
        defaults.set("cards", forKey: CityViewPreference.storageKey)
        let disk = PrimaryTestDisk(try JSONEncoder().encode(cities))
        let store = CityStore(storage: disk.storage)
        let model = TimeDialViewModel(); model.tickerTask?.cancel()
        model.beginDialDrag(); model.baseTime = instant; model.updateDialRotation(-15)
        let frozen = model.selectedInstant
        let frozenSteps = model.dialSteps
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        let host = UIHostingController(rootView: PrimaryBindingFixture(store: store, model: model))
        window.rootViewController = host; window.makeKeyAndVisible()
        defer { window.isHidden = true; previous?.makeKeyAndVisible() }
        func findList(_ vc: UIViewController) -> CityListReorderViewController? {
            (vc as? CityListReorderViewController) ?? vc.children.lazy.compactMap(findList).first
        }
        func findMap(_ view: UIView) -> WorldMapScrollView? {
            (view as? WorldMapScrollView) ?? view.subviews.lazy.compactMap(findMap).first
        }
        try await Task.sleep(for: .milliseconds(1000))
        host.view.layoutIfNeeded()
        let controller = try XCTUnwrap(findList(host))
        let map = try XCTUnwrap(findMap(host.view))
        XCTAssertEqual(map.markers.filter(\.isPrimary).map(\.cityID), [cities[0].id])
        func capture(_ name: String) {
            let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
                window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
            }
            let attachment = XCTAttachment(image: image)
            attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
        }
        capture("primary-before-reorder")
        let list = controller.collectionView
        let to = try XCTUnwrap(list.layoutAttributesForItem(at: IndexPath(item: 0, section: 0))).frame
        let from = try XCTUnwrap(list.layoutAttributesForItem(at: IndexPath(item: 1, section: 0))).frame
        let press = PrimaryTestLongPress()
        press.point = CGPoint(x: from.midX, y: from.midY); press.simulatedState = .began
        controller.handleLongPress(press)
        XCTAssertTrue(controller.isReordering)
        for step in 1...12 {
            let progress = CGFloat(step) / 12
            press.point = CGPoint(x: from.midX + (to.midX - from.midX) * progress,
                                  y: from.midY + (to.midY - from.midY) * progress)
            press.simulatedState = .changed; controller.handleLongPress(press)
            try await Task.sleep(for: .milliseconds(30))
        }
        try await Task.sleep(for: .milliseconds(250))
        press.simulatedState = .ended; controller.handleLongPress(press)
        try await Task.sleep(for: .milliseconds(350))
        XCTAssertEqual(store.cities.primaryCity?.id, cities[1].id)
        XCTAssertEqual(store.cities.first?.id, cities[1].id)
        XCTAssertEqual(map.markers.filter(\.isPrimary).map(\.cityID), [cities[1].id])
        XCTAssertTrue(findMap(host.view) === map)
        XCTAssertTrue(findList(host) === controller)
        XCTAssertTrue(controller.actionCell(for: cities[1].id)?.accessibilityLabel?.contains(", Primary,") == true)
        XCTAssertTrue(controller.actionCell(for: cities[0].id)?.accessibilityLabel?.contains("plus 7h") == true)
        XCTAssertFalse(controller.actionCell(for: cities[0].id)?.accessibilityLabel?.contains(", Primary,") == true)
        XCTAssertTrue(controller.actionCell(for: cities[2].id)?.accessibilityLabel?.contains("minus 8h") == true)
        capture("primary-after-reorder")
        let afterCards = store.cities
        for mode in ["basic", "compact", "cards"] {
            defaults.set(mode, forKey: CityViewPreference.storageKey)
            try await Task.sleep(for: .milliseconds(120))
            XCTAssertTrue(findList(host) === controller)
            XCTAssertEqual(controller.citiesLocal, afterCards)
            XCTAssertEqual(controller.citiesLocal.primaryCity?.id, cities[1].id)
        }
        defaults.set("basic", forKey: CityViewPreference.storageKey)
        try await Task.sleep(for: .milliseconds(120))
        controller.collectionView(list, moveItemAt: IndexPath(item: 2, section: 0), to: IndexPath(item: 0, section: 0))
        try await Task.sleep(for: .milliseconds(180))
        defaults.set("cards", forKey: CityViewPreference.storageKey)
        try await Task.sleep(for: .milliseconds(180))
        XCTAssertEqual(store.cities.primaryCity?.id, cities[2].id)
        XCTAssertEqual(map.markers.filter(\.isPrimary).map(\.cityID), [cities[2].id])
        XCTAssertEqual(controller.selectedInstant, frozen)
        XCTAssertEqual(model.selectedInstant, frozen)
        XCTAssertEqual(model.dialSteps, frozenSteps)
        let relaunched = CityStore(storage: disk.storage)
        XCTAssertEqual(relaunched.cities, store.cities)
        XCTAssertEqual(relaunched.cities.primaryCity?.id, cities[2].id)
        controller.deleteCity(id: cities[2].id)
        try await Task.sleep(for: .milliseconds(350))
        XCTAssertEqual(store.cities.primaryCity?.id, cities[1].id)
        XCTAssertEqual(map.markers.filter(\.isPrimary).map(\.cityID), [cities[1].id])
        XCTAssertEqual(CityStore(storage: disk.storage).cities, store.cities)
    }

    func testScrolledLastRowAutoScrollCommitsPrimaryWithPendingRefresh() async throws {
        let many = (0..<13).map { City(name: "City \($0)", timeZoneID: "Europe/Paris", canonicalID: "city:edge-\($0)") }
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        let controller = CityListReorderViewController()
        window.rootViewController = controller; window.makeKeyAndVisible()
        defer { window.isHidden = true; previous?.makeKeyAndVisible() }
        apply(controller, many)
        var published = many
        controller.onCitiesChanged = { published = $0 }
        let list = controller.collectionView
        list.scrollToItem(at: IndexPath(item: 12, section: 0), at: .bottom, animated: false)
        list.layoutIfNeeded()
        try await Task.sleep(for: .milliseconds(120))
        XCTAssertGreaterThan(list.contentOffset.y, 0)
        let from = try XCTUnwrap(list.layoutAttributesForItem(at: IndexPath(item: 12, section: 0))).frame
        let firstPosition = try XCTUnwrap(list.layoutAttributesForItem(at: IndexPath(item: 0, section: 0))).frame
        let press = PrimaryTestLongPress()
        press.point = CGPoint(x: from.midX, y: from.midY); press.simulatedState = .began
        controller.handleLongPress(press)
        XCTAssertTrue(controller.isReordering)
        // A deferred clock/content refresh still contains the original order.
        apply(controller, many)
        XCTAssertNotNil(controller.pendingExternalState)
        press.point = CGPoint(x: from.midX, y: list.bounds.minY + list.adjustedContentInset.top + 8)
        press.simulatedState = .changed; controller.handleLongPress(press)
        for _ in 0..<60 {
            if list.contentOffset.y <= -list.adjustedContentInset.top + 0.5 { break }
            try await Task.sleep(for: .milliseconds(100))
        }
        XCTAssertEqual(list.contentOffset.y, -list.adjustedContentInset.top, accuracy: 1)
        // During movement, index 0's old item can already be displaced. Aim at
        // the original top-left grid slot, not that displaced item's attributes.
        press.point = CGPoint(x: firstPosition.midX, y: firstPosition.midY)
        controller.handleLongPress(press)
        try await Task.sleep(for: .milliseconds(250))
        press.simulatedState = .ended; controller.handleLongPress(press)
        try await Task.sleep(for: .milliseconds(150))
        XCTAssertEqual(controller.citiesLocal.first?.id, many[12].id)
        XCTAssertEqual(published.primaryCity?.id, many[12].id)
        XCTAssertEqual(controller.citiesLocal, published)
        XCTAssertEqual(Set(published.map(\.id)).count, many.count)
        XCTAssertEqual(controller.selectedInstant, instant)
    }

    func testNativeMovesAndCancellationAcrossDuoViewportsCloseActions() async throws {
        func layout(_ status: DuoHingeState.Status, width: CGFloat, height: CGFloat, rail: Bool?) -> DuoLayoutConfiguration {
            var hinge = DuoHingeState(); hinge.receive(status)
            let portrait = rail == nil
            return .resolve(.init(hinge: hinge, bounds: CGRect(x: 0, y: 0, width: width, height: height),
                safeContent: portrait ? CGRect(x: 0, y: 84, width: width, height: height - 84) :
                    CGRect(x: rail == false ? 84 : 0, y: 0, width: width - 84, height: height - 34),
                railOnRight: rail, occlusions: portrait ? [CGRect(x: 529, y: 0, width: 140, height: 84)] : [], divisions: []))
        }
        let layouts = [layout(.closed, width: 466, height: 678, rail: true),
                       layout(.fullyOpen, width: 951, height: 669, rail: true),
                       layout(.partiallyOpen, width: 800, height: 669, rail: true),
                       layout(.fullyOpen, width: 669, height: 951, rail: nil),
                       layout(.partiallyOpen, width: 669, height: 951, rail: nil),
                       layout(.fullyOpen, width: 469, height: 669, rail: false),
                       layout(.fullyOpen, width: 469, height: 669, rail: true)]
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene); let parent = UIViewController()
        window.rootViewController = parent; window.makeKeyAndVisible()
        defer { window.isHidden = true; previous?.makeKeyAndVisible() }
        let controller = CityListReorderViewController()
        parent.addChild(controller); parent.view.addSubview(controller.view); controller.didMove(toParent: parent)
        var published = cities
        controller.onCitiesChanged = { published = $0 }
        var renameCount = 0
        controller.onRenameRequested = { _ in renameCount += 1 }
        for configuration in layouts {
            controller.view.frame = CGRect(origin: .zero, size: configuration.list.size)
            controller.prepareDuoLayout(viewport: configuration.list.size, showsLogo: !configuration.isPortrait,
                                        horizontalInset: configuration.listHorizontalInset)
            apply(controller, cities)
            let list = controller.collectionView
            list.setContentOffset(.zero, animated: false)
            try await Task.sleep(for: .milliseconds(100))
            let frames = try (0..<5).map { try XCTUnwrap(list.layoutAttributesForItem(at: IndexPath(item: $0, section: 0))).frame }
            XCTAssertEqual(frames[0].minY, frames[1].minY)
            XCTAssertLessThan(frames[0].minX, frames[1].minX)
            XCTAssertEqual(frames[2].minX, frames[0].minX)
            XCTAssertGreaterThan(frames[2].minY, frames[0].minY)
            XCTAssertEqual(frames[4].minX, frames[0].minX)
            for (source, destination, cancelled) in [(1, 0, false), (2, 0, false), (4, 0, false), (0, 3, false), (3, 0, true)] {
                let before = controller.citiesLocal
                controller.setOpenActionsCityID(before[source].id)
                list.scrollToItem(at: IndexPath(item: source, section: 0), at: .centeredVertically, animated: false)
                list.layoutIfNeeded()
                let from = try XCTUnwrap(list.layoutAttributesForItem(at: IndexPath(item: source, section: 0))).frame
                let press = PrimaryTestLongPress()
                press.point = CGPoint(x: from.midX, y: from.midY); press.simulatedState = .began
                controller.handleLongPress(press)
                XCTAssertTrue(controller.isReordering)
                XCTAssertNil(controller.openActionsCityID)
                XCTAssertNil(controller.actionSwipeCityID)
                controller.renameCity(id: before[source].id)
                controller.deleteCity(id: before[source].id)
                let swipe = UIPanGestureRecognizer()
                controller.handleCardActionPan(swipe)
                XCTAssertNil(controller.openActionsCityID)
                // Keep native scrolling active while moving from an offscreen final row.
                list.setContentOffset(.zero, animated: false); list.layoutIfNeeded()
                let target = try XCTUnwrap(list.layoutAttributesForItem(at: IndexPath(item: destination, section: 0))).frame
                press.point = CGPoint(x: target.midX, y: target.midY); press.simulatedState = .changed
                controller.handleLongPress(press)
                try await Task.sleep(for: .milliseconds(250))
                press.simulatedState = cancelled ? .cancelled : .ended; controller.handleLongPress(press)
                try await Task.sleep(for: .milliseconds(100))
                var expected = before
                if !cancelled { let city = expected.remove(at: source); expected.insert(city, at: destination) }
                XCTAssertEqual(controller.citiesLocal, expected)
                XCTAssertEqual(published, expected)
                XCTAssertEqual(controller.citiesLocal.primaryCity?.id, expected.first?.id)
                XCTAssertEqual(Set(controller.citiesLocal.map(\.id)).count, 5)
                XCTAssertEqual(renameCount, 0)
                XCTAssertEqual(controller.selectedInstant, instant)
            }
        }
    }
}

@MainActor private final class PrimaryTestDisk {
    var data: Data
    init(_ data: Data) { self.data = data }
    var storage: CityStore.Storage {
        .init(read: { [self] _ in data },
              write: { [self] value, url in if url.lastPathComponent == "cities.json" { data = value } },
              sharedDefaults: { _ in nil }, reloadWidgets: {})
    }
}
@MainActor private final class PrimaryTestLongPress: UILongPressGestureRecognizer {
    var simulatedState: UIGestureRecognizer.State = .possible
    var point = CGPoint.zero
    override var state: UIGestureRecognizer.State { get { simulatedState } set { simulatedState = newValue } }
    override func location(in view: UIView?) -> CGPoint { point }
}
@MainActor private struct PrimaryBindingFixture: View {
    @ObservedObject var store: CityStore
    @ObservedObject var model: TimeDialViewModel
    var body: some View {
        VStack(spacing: 0) {
            CityListReorderUIKitView(cities: $store.cities, selectedInstant: model.selectedInstant,
                userCurrentLocationItem: nil, topSafeAreaInset: 0, bottomContentInset: 0,
                onRenameRequested: { _ in }, onCitySelected: { _ in })
                .frame(height: 430)
            WorldMapObservedContent(viewModel: model, cityStore: store,
                viewportSize: CGSize(width: 393, height: 150), horizontalPosition: .constant(0.7))
                .frame(height: 150)
        }.environment(\.appTheme, .light)
    }
}

private final class PrimaryTestFileManager: FileManager, @unchecked Sendable {
    let root: URL
    init(root: URL) { self.root = root; super.init() }
    override func url(for directory: FileManager.SearchPathDirectory, in domain: FileManager.SearchPathDomainMask,
                      appropriateFor url: URL?, create shouldCreate: Bool) throws -> URL {
        if directory == .applicationSupportDirectory { return root }
        return try super.url(for: directory, in: domain, appropriateFor: url, create: shouldCreate)
    }
}
