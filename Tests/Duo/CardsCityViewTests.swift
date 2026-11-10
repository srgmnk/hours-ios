import XCTest
import SwiftUI
@testable import MapHarness

@MainActor final class CardsCityViewTests: XCTestCase {
    let instant = Date(timeIntervalSince1970: 1735736400)
    var cities: [City] {
        [City(name: "Bangkok", timeZoneID: "Asia/Bangkok", canonicalID: "city:bangkok"),
         City(name: "Saint Petersburg", timeZoneID: "Europe/Moscow", canonicalID: "city:spb"),
         City(name: "Los Angeles", timeZoneID: "America/Los_Angeles", canonicalID: "city:la"),
         City(name: "London", timeZoneID: "Europe/London", canonicalID: "city:london"),
         City(name: "Perm", timeZoneID: "Asia/Yekaterinburg", canonicalID: "city:perm")]
    }
    func apply(_ controller: CityListReorderViewController, cities: [City]? = nil,
               style: CityViewPreference = .cards, instant: Date? = nil) {
        controller.view.backgroundColor = UIColor(AppTheme.light.screenBackground)
        controller.apply(cities: cities ?? self.cities, selectedInstant: instant ?? self.instant,
                         userCurrentLocationItem: nil, cityViewPreference: style,
                         topInset: 25, bottomInset: 130, cardBackgroundColor: AppTheme.light.surfaceCard)
        controller.view.layoutIfNeeded()
        controller.collectionView.layoutIfNeeded()
    }
    func testTwoColumnsOddRowsAndViewportResizing() throws {
        let controller = CityListReorderViewController()
        controller.loadViewIfNeeded()
        for width: CGFloat in [393, 382, 316, 340, 455, 461, 636] {
            controller.view.frame = CGRect(x: 0, y: 0, width: width, height: 669)
            controller.prepareDuoLayout(viewport: CGSize(width: width, height: 669))
            apply(controller)
            let list = controller.collectionView
            let frames = try (0..<5).map { try XCTUnwrap(list.layoutAttributesForItem(at: IndexPath(item: $0, section: 0))).frame }
            XCTAssertEqual(list.numberOfItems(inSection: 0), 5)
            XCTAssertEqual(frames[0].width, (width - 24) / 2, accuracy: 0.5)
            XCTAssertEqual(frames[0].height, 200)
            XCTAssertEqual(frames[0].minX, 8)
            XCTAssertEqual(frames[1].minY, frames[0].minY)
            XCTAssertEqual(frames[1].minX - frames[0].maxX, 8, accuracy: 0.5)
            XCTAssertEqual(frames[2].minY - frames[0].maxY, 8)
            XCTAssertEqual(frames[4].minX, frames[0].minX)
            XCTAssertEqual(frames[4].height, 200)
        }
    }
    func testReorderingAcrossColumnsRowsAndPersistenceDerivesPrimaryFromOrder() throws {
        let controller = CityListReorderViewController()
        controller.loadViewIfNeeded(); apply(controller)
        let list = controller.collectionView
        for (from, to) in [(0, 1), (1, 4), (4, 2)] {
            let moved = controller.citiesLocal[from].id
            controller.collectionView(list, moveItemAt: IndexPath(item: from, section: 0), to: IndexPath(item: to, section: 0))
            XCTAssertEqual(controller.citiesLocal[to].id, moved)
            XCTAssertEqual(controller.citiesLocal.primaryCity?.id, controller.citiesLocal.first?.id)
            let data = try JSONEncoder().encode(controller.citiesLocal)
            let restored = try JSONDecoder().decode([City].self, from: data)
            XCTAssertEqual(restored, controller.citiesLocal)
            XCTAssertEqual(restored.primaryCity?.id, restored.first?.id)
        }
        // A clock update arriving during drag cannot restore the old order.
        controller.reorderOriginalCities = cities
        XCTAssertEqual(controller.mergedPendingCities(cities), controller.citiesLocal)
        apply(controller, cities: controller.citiesLocal, style: .basic)
        controller.collectionView(list, moveItemAt: IndexPath(item: 0, section: 0), to: IndexPath(item: 1, section: 0))
        XCTAssertEqual(controller.citiesLocal.primaryCity?.id, controller.citiesLocal.first?.id)
    }
    func testLegacyCityRecordsStillInferFirstPrimary() throws {
        let restored = try JSONDecoder().decode([City].self, from: JSONEncoder().encode(cities))
        XCTAssertEqual(restored.primaryCity?.id, restored.first?.id)
    }
    func testVisibleCardsUpdateTimeWithoutReplacingCollection() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let controller = CityListReorderViewController()
        let window = UIWindow(windowScene: scene)
        window.rootViewController = controller; window.makeKeyAndVisible()
        defer { window.isHidden = true; previous?.makeKeyAndVisible() }
        apply(controller)
        try await Task.sleep(for: .milliseconds(150))
        controller.collectionView.layoutIfNeeded()
        let collection = controller.collectionView
        let cell = try XCTUnwrap(collection.cellForItem(at: IndexPath(item: 0, section: 0)))
        apply(controller, instant: instant.addingTimeInterval(7200))
        XCTAssertTrue(collection === controller.collectionView)
        XCTAssertTrue(collection.cellForItem(at: IndexPath(item: 0, section: 0)) === cell)
        XCTAssertEqual(controller.selectedInstant, instant.addingTimeInterval(7200))
        XCTAssertNil(controller.trailingSwipeActionsConfiguration(for: IndexPath(item: 0, section: 0)))
        apply(controller, style: .basic)
        XCTAssertNotNil(controller.trailingSwipeActionsConfiguration(for: IndexPath(item: 0, section: 0)))
    }
    func testActionsAreIdentityBasedAndReuseDoesNotTransferThem() async throws {
        let controller = CityListReorderViewController()
        controller.loadViewIfNeeded(); apply(controller)
        controller.setOpenActionsCityID(cities[1].id)
        XCTAssertEqual(controller.openActionsCityID, cities[1].id)
        controller.setOpenActionsCityID(cities[3].id)
        XCTAssertEqual(controller.openActionsCityID, cities[3].id)
        // New clock values and cell configuration preserve the same identity.
        apply(controller, instant: instant.addingTimeInterval(600))
        XCTAssertEqual(controller.openActionsCityID, cities[3].id)
        let cell = CityListReorderCollectionCell(frame: CGRect(x: 0, y: 0, width: 184.5, height: 200))
        for city in [cities[3], cities[0], cities[3]] {
            cell.prepareForReuse()
            cell.configure(city: city, selectedInstant: instant, referenceTimeZone: cities[0].timeZone,
                           isCurrent: city.id == cities[0].id, isUserCurrentLocation: false,
                           cityViewPreference: .cards, cardBackgroundColor: .white,
                           showsActions: controller.openActionsCityID == city.id)
            XCTAssertNotNil(cell.contentConfiguration)
        }
        controller.scrollViewWillBeginDragging(controller.collectionView)
        XCTAssertNil(controller.openActionsCityID)
        controller.setOpenActionsCityID(cities[1].id)
        apply(controller, style: .compact)
        XCTAssertNil(controller.openActionsCityID)
        XCTAssertFalse(controller.cardActionPan.isEnabled)
        apply(controller)
        controller.setOpenActionsCityID(cities[1].id)
        apply(controller, cities: cities.filter { $0.id != cities[1].id })
        XCTAssertNil(controller.openActionsCityID)
        controller.setOpenActionsCityID("missing")
        XCTAssertNil(controller.openActionsCityID)
    }

    func testActionsReuseRenameDeleteAndDetailsCallbacks() async throws {
        let controller = CityListReorderViewController()
        controller.loadViewIfNeeded(); apply(controller)
        var renamed: City?, selected: City?, published: [City]?
        controller.onRenameRequested = { renamed = $0 }
        controller.onCitySelected = { selected = $0 }
        controller.onCitiesChanged = { published = $0 }
        controller.setOpenActionsCityID(cities[1].id)
        controller.renameCity(id: cities[1].id)
        await Task.yield()
        try await Task.sleep(for: .milliseconds(30))
        XCTAssertEqual(renamed?.id, cities[1].id)
        XCTAssertNil(controller.openActionsCityID)
        controller.selectCity(id: cities[2].id)
        try await Task.sleep(for: .milliseconds(30))
        XCTAssertEqual(selected?.id, cities[2].id)
        controller.setOpenActionsCityID(cities[3].id)
        controller.deleteCity(id: cities[3].id)
        try await Task.sleep(for: .milliseconds(50))
        XCTAssertNil(controller.openActionsCityID)
        XCTAssertFalse(controller.citiesLocal.contains { $0.id == cities[3].id })
        XCTAssertEqual(published?.map(\.id), controller.citiesLocal.map(\.id))
        controller.isReordering = true
        renamed = nil
        controller.renameCity(id: cities[0].id)
        controller.deleteCity(id: cities[0].id)
        XCTAssertNil(renamed)
        XCTAssertEqual(controller.citiesLocal.count, 4)
        controller.setOpenActionsCityID(cities[0].id)
        XCTAssertNil(controller.openActionsCityID)
    }

    func testOutsideTapDismissesWithoutOpeningDetails() {
        let controller = CityListReorderViewController()
        controller.loadViewIfNeeded(); apply(controller)
        controller.setOpenActionsCityID(cities[0].id)
        controller.handleOutsideActionTap()
        XCTAssertNil(controller.openActionsCityID)
        XCTAssertTrue(controller.isTapToOpenSuppressed)
    }

    func testSimulatorAppearanceViewportAndActionsCaptures() async throws {
        let defaults = UserDefaults.standard
        let saved = defaults.object(forKey: AppTimeFormatPreference.storageKey)
        defer { defaults.set(saved, forKey: AppTimeFormatPreference.storageKey) }
        defaults.set("twentyFourHour", forKey: AppTimeFormatPreference.storageKey)
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        let parent = UIViewController()
        window.rootViewController = parent; window.makeKeyAndVisible()
        defer { window.isHidden = true; previous?.makeKeyAndVisible() }
        let controller = CityListReorderViewController()
        parent.addChild(controller); parent.view.addSubview(controller.view); controller.didMove(toParent: parent)
        let fixtures: [(String, CGSize, CGFloat, Bool)] = [
            ("iphone", CGSize(width: 393, height: 720), 8, true),
            ("duo-outer", CGSize(width: 382, height: 678), 8, true),
            ("duo-landscape-open", CGSize(width: 340, height: 669), 8, true),
            ("duo-landscape-partial", CGSize(width: 316, height: 669), 8, true),
            ("duo-portrait-open", CGSize(width: 669, height: 475), 104, false),
            ("duo-portrait-partial", CGSize(width: 669, height: 475), 104, false),
            ("duo-split-left", CGSize(width: 455, height: 669), 8, true),
            ("duo-split-right", CGSize(width: 340, height: 669), 8, true)]
        for dark in [false, true] {
            let theme = dark ? AppTheme.dark : AppTheme.light
            window.overrideUserInterfaceStyle = dark ? .dark : .light
            for (name, size, inset, logo) in fixtures {
                controller.view.frame = CGRect(origin: .zero, size: size)
                controller.view.backgroundColor = UIColor(theme.screenBackground)
                controller.prepareDuoLayout(viewport: name == "iphone" ? nil : size, showsLogo: logo, horizontalInset: inset)
                controller.apply(cities: cities, selectedInstant: instant, userCurrentLocationItem: nil,
                                 cityViewPreference: .cards, topInset: logo ? 25 : 20, bottomInset: 130,
                                 cardBackgroundColor: theme.surfaceCard)
                controller.updatePortraitBlur(theme: theme, colorScheme: dark ? .dark : .light)
                controller.view.layoutIfNeeded()
                try await Task.sleep(for: .milliseconds(120))
                controller.collectionView.layoutIfNeeded()
                for actions in [false, true] {
                    controller.setOpenActionsCityID(actions ? cities[3].id : nil)
                    try await Task.sleep(for: .milliseconds(300))
                    let format = UIGraphicsImageRendererFormat(); format.scale = 2
                    let image = UIGraphicsImageRenderer(bounds: controller.view.bounds, format: format).image { _ in
                        XCTAssertTrue(controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true))
                    }
                    let attachment = XCTAttachment(image: image)
                    attachment.name = "cards-\(name)-\(dark ? "dark" : "light")-\(actions ? "actions" : "normal")"
                    attachment.lifetime = .keepAlways; add(attachment)
                    for cell in controller.collectionView.visibleCells {
                        XCTAssertEqual(cell.frame.height, 200, accuracy: 0.5)
                    }
                }
            }
        }
    }

    func testNativeGridMovementCommitsAndCancellationKeepsOrder() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        let controller = CityListReorderViewController()
        window.rootViewController = controller; window.makeKeyAndVisible()
        defer { window.isHidden = true; previous?.makeKeyAndVisible() }
        apply(controller)
        try await Task.sleep(for: .milliseconds(200))
        let list = controller.collectionView
        for (source, destination, cancel) in [(0, 1, false), (1, 4, false), (4, 0, true)] {
            let before = controller.citiesLocal
            let from = IndexPath(item: source, section: 0)
            let to = IndexPath(item: destination, section: 0)
            list.scrollToItem(at: to, at: .centeredVertically, animated: false)
            list.layoutIfNeeded()
            let frame = try XCTUnwrap(list.layoutAttributesForItem(at: to)).frame
            controller.setOpenActionsCityID(nil)
            XCTAssertTrue(list.beginInteractiveMovementForItem(at: from))
            controller.isReordering = true
            controller.reorderOriginalCities = before
            controller.draggedCityID = before[source].id
            list.updateInteractiveMovementTargetPosition(CGPoint(x: frame.midX, y: frame.midY))
            try await Task.sleep(for: .milliseconds(450))
            let image = UIGraphicsImageRenderer(bounds: controller.view.bounds).image { _ in
                controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
            }
            let attachment = XCTAttachment(image: image)
            attachment.name = "cards-native-drag-\(source)-to-\(destination)-cancel-\(cancel)"
            attachment.lifetime = .keepAlways; add(attachment)
            if cancel { list.cancelInteractiveMovement() } else { list.endInteractiveMovement() }
            controller.finishInteractiveMovement()
            try await Task.sleep(for: .milliseconds(250))
            if cancel { XCTAssertEqual(controller.citiesLocal, before) }
            else { XCTAssertEqual(controller.citiesLocal[destination].id, before[source].id) }
            XCTAssertEqual(controller.citiesLocal.primaryCity?.id, controller.citiesLocal.first?.id)
        }
    }

    func testCityStorePersistsPrimaryAlongWithOrderAndRename() throws {
        var stored = try JSONEncoder().encode(cities)
        var storage = CityStore.Storage()
        storage.read = { _ in stored }
        storage.write = { data, url in if url.lastPathComponent == "cities.json" { stored = data } }
        storage.sharedDefaults = { _ in nil }; storage.reloadWidgets = {}
        let store = CityStore(storage: storage)
        var reordered = store.cities
        let first = reordered.removeFirst(); reordered.append(first)
        reordered[1].customDisplayName = "LA"
        store.cities = reordered
        let reopened = CityStore(storage: storage)
        XCTAssertEqual(reopened.cities, reordered)
        XCTAssertEqual(reopened.cities.primaryCity?.id, reordered.first?.id)
        XCTAssertEqual(reopened.cities[1].displayName, "LA")
        reopened.cities.removeAll { $0.id == cities[0].id }
        let afterDelete = CityStore(storage: storage)
        XCTAssertEqual(afterDelete.cities.primaryCity?.id, afterDelete.cities.first?.id)
    }

    func testFullScreenModeThemeAndWheelUpdatesRetainController() async throws {
        let defaults = UserDefaults.standard
        let keys = [CityViewPreference.storageKey, AppTimeFormatPreference.storageKey, OnboardingStorageKey.hasCompleted]
        let saved = keys.map { defaults.object(forKey: $0) }
        defer { for (key, value) in zip(keys, saved) { defaults.set(value, forKey: key) } }
        defaults.set(true, forKey: OnboardingStorageKey.hasCompleted)
        defaults.set("cards", forKey: CityViewPreference.storageKey)
        defaults.set("twentyFourHour", forKey: AppTimeFormatPreference.storageKey)
        let data = try JSONEncoder().encode(cities)
        let store = CityStore(storage: .init(read: { _ in data }, write: { _, _ in },
                                            sharedDefaults: { _ in nil }, reloadWidgets: {}))
        let model = TimeDialViewModel(); model.tickerTask?.cancel()
        model.beginDialDrag(); model.baseTime = instant
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        let appearance = CardsTestAppearance()
        let host = UIHostingController(rootView: CardsTestScreen(model: model, store: store, appearance: appearance))
        window.rootViewController = host; window.makeKeyAndVisible()
        defer { window.isHidden = true; previous?.makeKeyAndVisible() }
        try await Task.sleep(for: .milliseconds(1200))
        func find(_ vc: UIViewController) -> CityListReorderViewController? {
            (vc as? CityListReorderViewController) ?? vc.children.lazy.compactMap { find($0) }.first
        }
        let controller = try XCTUnwrap(find(host))
        func capture(_ name: String) throws -> Data {
            host.view.layoutIfNeeded()
            let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
                window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
            }
            let attachment = XCTAttachment(image: image); attachment.name = name
            attachment.lifetime = .keepAlways; add(attachment)
            return try XCTUnwrap(image.pngData())
        }
        let light = try capture("screen-cards-light-primary-odd")
        model.updateDialRotation(-15)
        try await Task.sleep(for: .milliseconds(200))
        XCTAssertEqual(controller.selectedInstant, model.selectedInstant)
        XCTAssertNotEqual(light, try capture("screen-cards-wheel-forward"))
        for dark in [true, false] {
            appearance.dark = dark
            try await Task.sleep(for: .milliseconds(250))
            XCTAssertTrue(find(host) === controller)
            XCTAssertEqual(controller.traitCollection.userInterfaceStyle, dark ? .dark : .light)
            XCTAssertEqual(controller.cardTheme?.variant, dark ? .dark : .light)
            _ = try capture("screen-cards-\(dark ? "dark" : "light")")
        }
        controller.setOpenActionsCityID(cities[3].id)
        try await Task.sleep(for: .milliseconds(100))
        _ = try capture("screen-cards-actions")
        for style in ["basic", "cards", "compact", "cards", "basic"] {
            defaults.set(style, forKey: CityViewPreference.storageKey)
            try await Task.sleep(for: .milliseconds(200))
            XCTAssertTrue(find(host) === controller)
            XCTAssertEqual(controller.cityViewPreference.rawValue, style)
            XCTAssertNil(controller.openActionsCityID)
            _ = try capture("screen-switch-\(style)")
        }
        defaults.set("cards", forKey: CityViewPreference.storageKey)
        try await Task.sleep(for: .milliseconds(150))
        let twentyFour = try capture("screen-cards-24hour")
        defaults.set("twelveHour", forKey: AppTimeFormatPreference.storageKey)
        try await Task.sleep(for: .milliseconds(200))
        XCTAssertNotEqual(twentyFour, try capture("screen-cards-12hour"))
        XCTAssertTrue(find(host) === controller)
        store.cities.append(City(name: "Tokyo", timeZoneID: "Asia/Tokyo", canonicalID: "city:tokyo"))
        try await Task.sleep(for: .milliseconds(150))
        XCTAssertEqual(controller.collectionView.numberOfItems(inSection: 0), 6)
        store.cities.removeLast()
        try await Task.sleep(for: .milliseconds(150))
        XCTAssertEqual(controller.collectionView.numberOfItems(inSection: 0), 5)
        let start = ContinuousClock.now
        for index in 0..<60 {
            controller.collectionView.setContentOffset(CGPoint(x: 0, y: CGFloat(index % 15) * 20), animated: false)
            controller.collectionView.layoutIfNeeded()
        }
        let elapsed = start.duration(to: .now)
        let timing = XCTAttachment(string: "60 native scroll/layout steps: \(elapsed). Simulator timing, not device FPS.")
        timing.name = "cards-scroll-cost"; timing.lifetime = .keepAlways; add(timing)
    }

    func testNarrowPartialPaneFitsTwelveHourTimeAndFractionalDSTMetadata() throws {
        let defaults = UserDefaults.standard
        let saved = defaults.object(forKey: AppTimeFormatPreference.storageKey)
        defer { defaults.set(saved, forKey: AppTimeFormatPreference.storageKey) }
        let summer = Date(timeIntervalSince1970: 1751371200)
        let cases: [(String, City, Date, Bool)] = [
            ("am", City(name: "Saint John's", timeZoneID: "America/St_Johns"), summer, false),
            ("pm", City(name: "Saint John's", timeZoneID: "America/St_Johns"), summer.addingTimeInterval(43_200), false),
            ("primary", City(name: "Chatham", timeZoneID: "Pacific/Chatham"), Date(timeIntervalSince1970: 1735689600), true)
        ]
        for (name, city, instant, primary) in cases {
            for format in ["twelveHour", "twentyFourHour"] {
                defaults.set(format, forKey: AppTimeFormatPreference.storageKey)
                for dark in [false, true] {
                    let theme = dark ? AppTheme.dark : AppTheme.light
                    let card = CityCardView(city: city, selectedInstant: instant,
                                            referenceTimeZone: cities[0].timeZone, isCurrent: primary,
                                            cityViewPreference: .cards, cardBackgroundColor: theme.surfaceCard)
                        .environment(\.appTheme, theme)
                    let renderer = ImageRenderer(content: card)
                    renderer.proposedSize = ProposedViewSize(width: 146, height: 200)
                    renderer.scale = 3
                    let image = try XCTUnwrap(renderer.uiImage)
                    XCTAssertEqual(image.size.width, 146, accuracy: 0.5)
                    XCTAssertEqual(image.size.height, 200, accuracy: 0.5)
                    let attachment = XCTAttachment(image: image)
                    attachment.name = "cards-narrow-\(name)-DST-\(format)-\(dark ? "dark" : "light")"
                    attachment.lifetime = .keepAlways; add(attachment)
                }
            }
        }
    }

    func testNativeAutoScrollAndCancelledOffscreenDrag() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        let controller = CityListReorderViewController()
        window.rootViewController = controller; window.makeKeyAndVisible()
        defer { window.isHidden = true; previous?.makeKeyAndVisible() }
        let many = (0..<25).map { City(name: "City \($0)", timeZoneID: "UTC", canonicalID: "city:scroll-\($0)") }
        apply(controller, cities: many)
        try await Task.sleep(for: .milliseconds(200))
        let list = controller.collectionView
        let offset = list.contentOffset.y
        XCTAssertTrue(list.beginInteractiveMovementForItem(at: IndexPath(item: 0, section: 0)))
        controller.isReordering = true
        controller.updateInteractiveMovementTarget(CGPoint(x: list.bounds.maxX - 60, y: list.bounds.maxY - 4))
        try await Task.sleep(for: .milliseconds(1200))
        XCTAssertGreaterThan(list.contentOffset.y, offset, "Native movement must auto-scroll at the viewport edge")
        list.cancelInteractiveMovement(); controller.finishInteractiveMovement()
        XCTAssertEqual(controller.citiesLocal, many)
        for index in list.indexPathsForVisibleItems {
            XCTAssertEqual(list.layoutAttributesForItem(at: index)?.frame.height, 200)
        }
    }

    func testHorizontalActionGestureKeepsTheStartingCityAndRejectsVerticalScroll() {
        let controller = CityListReorderViewController()
        controller.loadViewIfNeeded()
        controller.view.frame = CGRect(x: 0, y: 0, width: 393, height: 720)
        apply(controller)
        let pan = CardsTestPan()
        controller.cardActionPan = pan
        pan.point = CGPoint(x: 260, y: 150)
        pan.speed = CGPoint(x: -200, y: 10)
        pan.shift = CGPoint(x: -40, y: 0)
        XCTAssertTrue(controller.gestureRecognizerShouldBegin(pan))
        pan.simulatedState = .began; controller.handleCardActionPan(pan)
        pan.point.x = 100; pan.shift.x = -200
        pan.simulatedState = .ended; controller.handleCardActionPan(pan)
        XCTAssertEqual(controller.openActionsCityID, cities[1].id)
        pan.speed = CGPoint(x: 10, y: 200)
        XCTAssertFalse(controller.gestureRecognizerShouldBegin(pan))
        pan.shift.x = 50
        pan.simulatedState = .ended; controller.handleCardActionPan(pan)
        XCTAssertNil(controller.openActionsCityID)
    }

    func testSequentialExpansionIsContinuousReversibleAndClamped() {
        // Native's trailing Delete expands before the inner Rename action.
        XCTAssertEqual(CardsActionExpansion.delete.progress(at: 0.2), 0.5, accuracy: 0.001)
        XCTAssertEqual(CardsActionExpansion.rename.progress(at: 0.2), 0)
        XCTAssertEqual(CardsActionExpansion.delete.progress(at: 0.5), 1)
        XCTAssertEqual(CardsActionExpansion.rename.progress(at: 0.5), 0)
        XCTAssertEqual(CardsActionExpansion.rename.progress(at: 0.825), 0.5, accuracy: 0.001)
        for action in [CardsActionExpansion.rename, .delete] {
            XCTAssertEqual(action.progress(at: -1), 0)
            XCTAssertEqual(action.progress(at: 2), 1)
            let forward = (0...100).map { action.progress(at: CGFloat($0) / 100) }
            let reverse = (0...100).reversed().map { action.progress(at: CGFloat($0) / 100) }
            XCTAssertEqual(forward, reverse.reversed())
            for (a, b) in zip(forward, forward.dropFirst()) {
                XCTAssertGreaterThanOrEqual(b, a)
                XCTAssertLessThan(b - a, 0.03)
            }
        }
    }

    func testNativeSizedActionHitAreasAndIncompleteSwipeSafety() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        let controller = CityListReorderViewController()
        window.rootViewController = controller; window.makeKeyAndVisible()
        defer { window.isHidden = true; previous?.makeKeyAndVisible() }
        apply(controller)
        try await Task.sleep(for: .milliseconds(150))
        controller.setOpenActionsCityID(cities[0].id)
        let cell = try XCTUnwrap(controller.actionCell(for: cities[0].id))
        try await Task.sleep(for: .milliseconds(300))
        let center = CGPoint(x: cell.frame.midX, y: cell.frame.minY + 100)
        for offset: CGFloat in [-30, 30] {
            XCTAssertTrue(controller.isActionButtonPoint(CGPoint(x: center.x + offset + 24, y: center.y)))
            XCTAssertFalse(controller.isActionButtonPoint(CGPoint(x: center.x + offset, y: center.y + 26)))
        }
        XCTAssertFalse(controller.isActionButtonPoint(center)) // 10pt gap between circles
        for progress: CGFloat in [0.2, 0.5, 0.825, 1] {
            cell.actionPresentation.updateInteractiveProgress(progress)
            XCTAssertFalse(cell.actionPresentation.buttonsEnabled)
            XCTAssertFalse(controller.isActionButtonPoint(CGPoint(x: center.x + 30, y: center.y)))
        }
        cell.actionPresentation.settle(open: true)
        try await Task.sleep(for: .milliseconds(300))
        XCTAssertTrue(cell.actionPresentation.buttonsEnabled)
        controller.setOpenActionsCityID(nil)
        XCTAssertFalse(cell.actionPresentation.buttonsEnabled)
    }

    func testInteractiveSwipeProgressReversalCancellationAndCellIdentity() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        let controller = CityListReorderViewController()
        window.rootViewController = controller; window.makeKeyAndVisible()
        defer { window.isHidden = true; previous?.makeKeyAndVisible() }
        apply(controller)
        try await Task.sleep(for: .milliseconds(200))
        let first = try XCTUnwrap(controller.actionCell(for: cities[0].id))
        let second = try XCTUnwrap(controller.actionCell(for: cities[1].id))
        let host = first.contentView
        let presentation = first.actionPresentation
        let frame = first.frame
        let pan = CardsTestPan()
        var origin = CGPoint(x: frame.midX, y: frame.midY)
        func send(_ state: UIGestureRecognizer.State, _ x: CGFloat) {
            pan.simulatedState = state
            pan.shift = CGPoint(x: x, y: 0)
            pan.point = CGPoint(x: origin.x + x, y: origin.y)
            controller.handleCardActionPan(pan)
        }
        send(.began, 0)
        for x: CGFloat in [-12, -24, -72, -48, -12] {
            send(.changed, x)
            XCTAssertEqual(presentation.progress, -x / 96, accuracy: 0.001)
            XCTAssertFalse(presentation.buttonsEnabled)
            XCTAssertEqual(first.frame, frame)
            XCTAssertTrue(first.contentView === host)
            XCTAssertTrue(first.actionPresentation === presentation)
            XCTAssertEqual(second.actionPresentation.progress, 0)
            try await Task.sleep(for: .milliseconds(35))
        }
        send(.ended, -12)
        try await Task.sleep(for: .milliseconds(300))
        XCTAssertEqual(presentation.progress, 0)
        XCTAssertNil(controller.openActionsCityID)
        send(.began, 0); send(.changed, -70); send(.cancelled, -70)
        try await Task.sleep(for: .milliseconds(300))
        XCTAssertEqual(presentation.progress, 0)
        XCTAssertFalse(presentation.buttonsEnabled)
        // Fast opening uses the original strict >24pt threshold, not velocity.
        send(.began, 0); send(.ended, -25)
        XCTAssertEqual(controller.openActionsCityID, cities[0].id)
        XCTAssertFalse(presentation.buttonsEnabled)
        try await Task.sleep(for: .milliseconds(90))
        XCTAssertGreaterThan(presentation.presentedProgress, 0)
        XCTAssertLessThan(presentation.presentedProgress, 1)
        let interrupted = presentation.presentedProgress
        send(.began, 0)
        XCTAssertEqual(presentation.progress, interrupted, accuracy: 0.1)
        send(.changed, 12); send(.cancelled, 12)
        try await Task.sleep(for: .milliseconds(300))
        XCTAssertEqual(presentation.progress, 1)
        XCTAssertTrue(presentation.buttonsEnabled)
        // Content refresh during an interactive close must preserve its progress.
        send(.began, 0); send(.changed, 48)
        apply(controller, instant: instant.addingTimeInterval(60))
        XCTAssertTrue(first.actionPresentation === presentation)
        XCTAssertEqual(presentation.progress, 0.5, accuracy: 0.001)
        send(.changed, 12); send(.ended, 12)
        try await Task.sleep(for: .milliseconds(300))
        XCTAssertEqual(presentation.progress, 1)
        // Another card closes the previous one, while its own controls stay inert.
        origin = CGPoint(x: second.frame.midX, y: second.frame.midY)
        send(.began, 0); send(.changed, -48)
        XCTAssertNil(controller.openActionsCityID)
        XCTAssertEqual(presentation.progress, 0)
        XCTAssertEqual(second.actionPresentation.progress, 0.5)
        XCTAssertFalse(second.actionPresentation.buttonsEnabled)
        send(.ended, -48)
        try await Task.sleep(for: .milliseconds(300))
        XCTAssertEqual(controller.openActionsCityID, cities[1].id)
        XCTAssertTrue(second.actionPresentation.buttonsEnabled)
        controller.scrollViewWillBeginDragging(controller.collectionView)
        XCTAssertNil(controller.openActionsCityID)
        XCTAssertFalse(second.actionPresentation.buttonsEnabled)
        // Rapid transitions and mode changes cannot leave an old completion enabled.
        for _ in 0..<4 {
            send(.began, 0); send(.changed, -60); send(.ended, -60)
            controller.setOpenActionsCityID(nil)
        }
        apply(controller, style: .compact)
        try await Task.sleep(for: .milliseconds(300))
        XCTAssertFalse(second.actionPresentation.buttonsEnabled)
        XCTAssertNil(controller.actionSwipeCityID)
        apply(controller)
        XCTAssertEqual(controller.actionCell(for: cities[1].id)?.actionPresentation.progress, 0)
    }

    func testInteractiveRegionSnapshotsAcrossAppearanceAndDuoWidths() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        let parent = UIViewController()
        window.rootViewController = parent; window.makeKeyAndVisible()
        defer { window.isHidden = true; previous?.makeKeyAndVisible() }
        let controller = CityListReorderViewController()
        parent.addChild(controller); parent.view.addSubview(controller.view); controller.didMove(toParent: parent)
        for dark in [false, true] {
            let theme = dark ? AppTheme.dark : AppTheme.light
            window.overrideUserInterfaceStyle = dark ? .dark : .light
            controller.updateCardTheme(theme)
            for width: CGFloat in [393, 382, 316, 340, 455, 636] {
                controller.view.frame = CGRect(x: 0, y: 0, width: width, height: 669)
                controller.prepareDuoLayout(viewport: CGSize(width: width, height: 669))
                apply(controller)
                try await Task.sleep(for: .milliseconds(100))
                let cell = try XCTUnwrap(controller.actionCell(for: cities[0].id))
                let originalFrame = cell.frame
                var snapshots = [Data]()
                for progress: CGFloat in [0, 0.25, 0.5, 0.75, 1] {
                    cell.actionPresentation.updateInteractiveProgress(progress)
                    try await Task.sleep(for: .milliseconds(35))
                    let image = UIGraphicsImageRenderer(bounds: cell.bounds).image { _ in
                        XCTAssertTrue(cell.drawHierarchy(in: cell.bounds, afterScreenUpdates: true))
                    }
                    snapshots.append(try XCTUnwrap(image.pngData()))
                    let attachment = XCTAttachment(image: image)
                    attachment.name = "swipe-\(Int(width))-\(dark ? "dark" : "light")-\(Int(progress * 100))"
                    attachment.lifetime = .keepAlways; add(attachment)
                    XCTAssertEqual(cell.frame, originalFrame)
                    XCTAssertFalse(cell.actionPresentation.buttonsEnabled)
                }
                XCTAssertEqual(Set(snapshots).count, 5)
            }
        }
    }

    func testRecordedInteractiveSwipeWalkthrough() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        let parent = UIViewController()
        window.rootViewController = parent; window.makeKeyAndVisible()
        defer { window.isHidden = true; previous?.makeKeyAndVisible() }
        let controller = CityListReorderViewController()
        parent.addChild(controller); parent.view.addSubview(controller.view); controller.didMove(toParent: parent)
        controller.view.frame = parent.view.bounds
        apply(controller)
        controller.apply(cities: cities, selectedInstant: instant, userCurrentLocationItem: nil,
                         cityViewPreference: .cards, topInset: 100, bottomInset: 130,
                         cardBackgroundColor: AppTheme.light.surfaceCard)
        let caption = UILabel(frame: CGRect(x: 16, y: 45, width: parent.view.bounds.width - 32, height: 50))
        caption.font = .systemFont(ofSize: 14, weight: .medium)
        caption.textColor = .darkGray; caption.numberOfLines = 2; caption.textAlignment = .center
        parent.view.addSubview(caption)
        let finger = UIView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        finger.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.35)
        finger.layer.cornerRadius = 12; finger.isUserInteractionEnabled = false; finger.isHidden = true
        parent.view.addSubview(finger)
        try await Task.sleep(for: .milliseconds(300))
        let pan = CardsTestPan()
        var item = 0
        func send(_ state: UIGestureRecognizer.State, _ x: CGFloat) {
            let frame = controller.collectionView.layoutAttributesForItem(at: IndexPath(item: item, section: 0))!.frame
            pan.simulatedState = state; pan.shift = CGPoint(x: x, y: 0)
            pan.point = CGPoint(x: frame.midX + x, y: frame.midY)
            finger.center = controller.collectionView.convert(pan.point, to: parent.view)
            finger.isHidden = state != .began && state != .changed
            controller.handleCardActionPan(pan)
        }
        func sweep(_ from: CGFloat, _ to: CGFloat) async throws {
            for step in 0...24 {
                send(.changed, from + (to - from) * CGFloat(step) / 24)
                try await Task.sleep(for: .milliseconds(40))
            }
        }
        print("CARDS_RECORDING_START \(Date().timeIntervalSince1970)")
        caption.text = "Automated gesture replay\nSlow opening — finger down"
        send(.began, 0); try await sweep(0, -96); send(.ended, -96)
        try await Task.sleep(for: .milliseconds(450))
        XCTAssertEqual(controller.openActionsCityID, cities[0].id)
        caption.text = "Interactive closing"
        send(.began, 0); try await sweep(0, 96); send(.ended, 96)
        try await Task.sleep(for: .milliseconds(450))
        caption.text = "Partial swipe — returns closed"
        send(.began, 0); try await sweep(0, -18); send(.ended, -18)
        try await Task.sleep(for: .milliseconds(450))
        XCTAssertNil(controller.openActionsCityID)
        caption.text = "Reverse before releasing"
        send(.began, 0); try await sweep(0, -72); try await sweep(-72, -8); send(.ended, -8)
        try await Task.sleep(for: .milliseconds(450))
        caption.text = "Fast opening — ease-out completion"
        send(.began, 0); send(.changed, -40); send(.ended, -40)
        try await Task.sleep(for: .milliseconds(600))
        caption.text = "Open another card — previous closes"
        item = 1; send(.began, 0); try await sweep(0, -96); send(.ended, -96)
        try await Task.sleep(for: .milliseconds(450))
        XCTAssertEqual(controller.openActionsCityID, cities[1].id)
        caption.text = "Scroll dismissal"
        controller.scrollViewWillBeginDragging(controller.collectionView)
        controller.collectionView.setContentOffset(CGPoint(x: 0, y: 100), animated: true)
        try await Task.sleep(for: .milliseconds(750))
        XCTAssertNil(controller.openActionsCityID)
        print("CARDS_RECORDING_END \(Date().timeIntervalSince1970)")
    }

    func testVoiceOverExposesActionsWithoutRequiringASwipe() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        let controller = CityListReorderViewController()
        window.rootViewController = controller; window.makeKeyAndVisible()
        defer { window.isHidden = true; previous?.makeKeyAndVisible() }
        apply(controller)
        try await Task.sleep(for: .milliseconds(200))
        func elements(_ root: NSObject) -> [NSObject] {
            var seen = Set<ObjectIdentifier>()
            func visit(_ object: NSObject) -> [NSObject] {
                guard seen.insert(ObjectIdentifier(object)).inserted else { return [] }
                var result = [object]
                if let view = object as? UIView { for child in view.subviews { result += visit(child) } }
                let count = object.accessibilityElementCount()
                if count > 0 && count < 1000 {
                    for index in 0..<count {
                        if let child = object.accessibilityElement(at: index) as? NSObject { result += visit(child) }
                    }
                }
                return result
            }
            return visit(root)
        }
        let names = elements(controller.view).flatMap { $0.accessibilityCustomActions ?? [] }.map(\.name)
        XCTAssertTrue(names.contains("Rename"))
        XCTAssertTrue(names.contains("Delete"))
        XCTAssertTrue(names.contains("City Details"))
        controller.setOpenActionsCityID(cities[1].id)
        try await Task.sleep(for: .milliseconds(100))
        let cell = try XCTUnwrap(controller.collectionView.cellForItem(at: IndexPath(item: 1, section: 0)))
        XCTAssertTrue(cell.accessibilityLabel?.contains("Saint Petersburg") == true)
        let rename = try XCTUnwrap(cell.accessibilityCustomActions?.first { $0.name == "Rename" })
        var renamed: City?
        controller.onRenameRequested = { renamed = $0 }
        XCTAssertEqual(rename.actionHandler?(rename), true)
        try await Task.sleep(for: .milliseconds(30))
        XCTAssertEqual(renamed?.id, cities[1].id)
        XCTAssertNil(controller.openActionsCityID)
    }

}


@MainActor private final class CardsTestPan: UIPanGestureRecognizer {
    var simulatedState: UIGestureRecognizer.State = .possible
    var point = CGPoint.zero
    var shift = CGPoint.zero
    var speed = CGPoint.zero
    override var state: UIGestureRecognizer.State {
        get { simulatedState }
        set { simulatedState = newValue }
    }
    override func location(in view: UIView?) -> CGPoint { point }
    override func translation(in view: UIView?) -> CGPoint { shift }
    override func velocity(in view: UIView?) -> CGPoint { speed }
}

@MainActor private final class CardsTestAppearance: ObservableObject {
    @Published var dark = false
}

@MainActor private struct CardsTestScreen: View {
    let model: TimeDialViewModel
    let store: CityStore
    @ObservedObject var appearance: CardsTestAppearance
    var body: some View {
        TimeDialScreen(viewModel: model).environmentObject(store)
            .environment(\.appTheme, appearance.dark ? .dark : .light)
            .preferredColorScheme(appearance.dark ? .dark : .light)
    }
}
