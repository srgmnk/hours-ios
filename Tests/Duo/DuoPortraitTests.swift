import XCTest
import SwiftUI
@testable import MapHarness

@MainActor final class DuoPortraitTests: XCTestCase {
    private func input(_ status: DuoHingeState.Status = .fullyOpen) -> DuoLayoutConfiguration.Input {
        var hinge = DuoHingeState(); hinge.receive(status)
        return .init(hinge: hinge, bounds: CGRect(x: 0, y: 0, width: 669, height: 951),
                     safeContent: CGRect(x: 0, y: 84, width: 669, height: 867), railOnRight: nil,
                     occlusions: [CGRect(x: 529, y: 0, width: 140, height: 84)], divisions: [])
    }

    func testPortraitBlurTracksEffectiveTopAndRetainsNativeList() async throws {
        let controller = CityListReorderViewController()
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        let parent = UIViewController(); window.rootViewController = parent
        window.makeKeyAndVisible()
        parent.addChild(controller); parent.view.addSubview(controller.view)
        controller.view.frame = CGRect(x:0,y:0,width:669,height:475)
        controller.didMove(toParent: parent)
        defer { window.isHidden = true; previous?.makeKeyAndVisible() }
        let cities = (0..<20).map { City(name: "City \($0)", timeZoneID: "UTC", canonicalID: "blur-\($0)") }
        controller.prepareDuoLayout(viewport: controller.view.bounds.size, showsLogo: false, horizontalInset: 104)
        let list = controller.collectionView
        let delegate = list.delegate
        for dark in [false, true] {
            let theme = dark ? AppTheme.dark : AppTheme.light
            window.overrideUserInterfaceStyle = dark ? .dark : .light
            window.layoutIfNeeded()
            try await Task.sleep(for: .milliseconds(150))
            window.backgroundColor = UIColor(theme.screenBackground)
            controller.view.backgroundColor = UIColor(theme.screenBackground)
            for style in [CityViewPreference.basic, .compact] {
                controller.apply(cities: cities, selectedInstant: Date(timeIntervalSince1970: 1793250000),
                                 userCurrentLocationItem: nil, cityViewPreference: style,
                                 topInset: 20, bottomInset: 24, cardBackgroundColor: theme.surfaceCard)
                controller.updatePortraitBlur(theme: theme, colorScheme: dark ? .dark : .light)
                controller.view.layoutIfNeeded()
                try await Task.sleep(for: .milliseconds(100))
                let overlay = try XCTUnwrap(controller.portraitBlur?.view)
                XCTAssertFalse(overlay.isUserInteractionEnabled)
                XCTAssertEqual(overlay.frame, CGRect(x: 0, y: 0, width: 669, height: 40))
                // Deliberately nonzero: top must be normalized against adjusted insets.
                list.contentInset.top = 12
                for (distance, opacity): (CGFloat, CGFloat) in [(0, 0), (20, 0.5), (40, 1), (85, 1), (0, 0), (-20, 0)] {
                    list.setContentOffset(CGPoint(x: 0, y: distance - list.adjustedContentInset.top), animated: false)
                    controller.scrollViewDidScroll(list)
                    XCTAssertEqual(overlay.alpha, opacity, accuracy: 0.001)
                    XCTAssertTrue(list.delegate === delegate)
                    XCTAssertTrue(controller.collectionView === list)
                    XCTAssertEqual(controller.citiesLocal.map(\.id), cities.map(\.id))
                    if distance >= 0 && distance <= 40 {
                        try await Task.sleep(for: .milliseconds(60))
                        let image = UIGraphicsImageRenderer(bounds: controller.view.bounds).image { _ in
                            XCTAssertTrue(controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true))
                        }
                        let attachment = XCTAttachment(image: image)
                        attachment.name = "list-blur-\(dark ? "dark" : "light")-\(style)-\(Int(distance))pt"
                        attachment.lifetime = .keepAlways; add(attachment)
                    }
                }
                list.contentInset.top = 0
                list.setContentOffset(CGPoint(x: 0, y: 200), animated: false)
                controller.scrollViewDidScroll(list)
                controller.lastDuoScrollAnchor = controller.captureDuoScrollAnchor()
                for portrait in [false, true] {
                    let size = portrait ? CGSize(width:669,height:475) : CGSize(width:340,height:669)
                    controller.prepareDuoLayout(viewport:size, showsLogo:!portrait, horizontalInset:portrait ? 104 : 8)
                    controller.updatePortraitBlur(theme:theme, colorScheme:dark ? .dark : .light)
                    controller.view.frame.size = size
                    controller.view.setNeedsLayout(); controller.view.layoutIfNeeded()
                    XCTAssertTrue(controller.portraitBlur?.view === overlay)
                    XCTAssertEqual(overlay.isHidden, !portrait)
                    let t = min(1,max(0,list.contentOffset.y + list.adjustedContentInset.top)/40)
                    XCTAssertEqual(overlay.alpha,t*t*(3-2*t),accuracy:0.001)
                }
            }
        }
    }

    func testFigmaPanelsWheelCardsAndControls() throws {
        let c = DuoLayoutConfiguration.resolve(input())
        XCTAssertEqual(c.arrangement, .innerPortrait)
        XCTAssertTrue(c.isInner); XCTAssertFalse(c.isTransition)
        XCTAssertEqual(c.map, CGRect(x: 0, y: 0, width: 669, height: 476))
        XCTAssertEqual(c.list, CGRect(x: 0, y: 476, width: 669, height: 475))
        XCTAssertEqual(c.mapViewport, c.map); XCTAssertEqual(c.mapDrawingFrame, c.map)
        XCTAssertEqual(c.map.union(c.list), c.content)
        XCTAssertNil(c.mapVisualViewport); XCTAssertNil(c.outerSwitcherFrame)
        XCTAssertEqual(c.wheelCenter, CGPoint(x: 334.5, y: 618))
        XCTAssertEqual(c.wheelClip, c.map)
        XCTAssertEqual(c.deltaCenter, CGPoint(x: 334.5, y: 445))
        XCTAssertEqual(c.blurFrame, CGRect(x: 0, y: 414, width: 669, height: 62))
        XCTAssertEqual(c.list.width - 2 * c.listHorizontalInset, 461)
        XCTAssertEqual(c.listTopInset, 20)
        XCTAssertEqual(c.controls, CGRect(x: 593, y: 821, width: 48, height: 106))
        XCTAssertTrue(c.usesCompactSettingsHeader)
        let canvas = c.mapGeometryProfile.canvas(in: c.map.size)
        XCTAssertEqual(canvas.side, 668 * 1.10); XCTAssertEqual(canvas.top, -93)
        XCTAssertEqual(WorldMapGeometryProfile.duoPortraitInitialCenter, (669 / 2 - 1) / 668, accuracy: 1e-8)
    }

    func testPortraitRequiresOpenHingeAndUnambiguousFullDisplayGeometry() {
        let portrait = DuoLayoutConfiguration.resolve(input())
        for status: DuoHingeState.Status in [.unavailable, .closed] {
            XCTAssertFalse(DuoLayoutConfiguration.resolve(input(status), previous: portrait).isPortrait)
        }
        var missingHinge = input(); missingHinge.hinge.receive(.unavailable)
        XCTAssertFalse(DuoLayoutConfiguration.resolve(missingHinge).isPortrait)
        let held = DuoLayoutConfiguration.resolve(missingHinge, previous: portrait)
        XCTAssertTrue(held.isPortrait); XCTAssertTrue(held.isTransition)
        XCTAssertEqual(held.map, portrait.map); XCTAssertEqual(held.list, portrait.list)
        for size in [CGSize(width: 402, height: 874), CGSize(width: 440, height: 956),
                     CGSize(width: 466, height: 678), CGSize(width: 469, height: 669),
                     CGSize(width: 951, height: 669), CGSize(width: 600, height: 900),
                     CGSize(width: 669, height: 669), CGSize(width: 669, height: 1024)] {
            var i = input(); i.bounds.size = size; i.safeContent.size.width = size.width
            XCTAssertFalse(DuoLayoutConfiguration.resolve(i, previous: portrait).isPortrait)
        }
        for edge in [true, false] {
            var i = input(); i.railOnRight = edge
            XCTAssertFalse(DuoLayoutConfiguration.resolve(i).isPortrait)
        }
        var i = input(); i.safeContent.origin.x = 84
        XCTAssertFalse(DuoLayoutConfiguration.resolve(i).isPortrait)
        i = input(); i.occlusions = []
        XCTAssertFalse(DuoLayoutConfiguration.resolve(i).isPortrait)
        i = input(); i.divisions = [CGRect(x: 0, y: 420, width: 669, height: 40)]
        XCTAssertFalse(DuoLayoutConfiguration.resolve(i).isPortrait)
        i = input(); i.occlusions.append(CGRect(x: 0, y: 475, width: 669, height: 20))
        XCTAssertFalse(DuoLayoutConfiguration.resolve(i).isPortrait)
    }

    func testMeasuredPartialPortraitUsesIdenticalConfigurationAndSurvivesPostureHandoffs() {
        // Native iOS 27.1 measurements for both portrait postures.
        var full = input()
        full.safeContent = CGRect(x: 0, y: 82, width: 669, height: 835)
        full.occlusions = [CGRect(x: 525, y: 0, width: 144, height: 82)]
        var partial = full; partial.hinge.receive(.partiallyOpen)
        partial.divisions = [CGRect(x: 0, y: 455.5, width: 669, height: 40)]
        let approved = DuoLayoutConfiguration.resolve(full)
        XCTAssertFalse(approved.isTransition)
        XCTAssertEqual(DuoLayoutConfiguration.resolve(partial), approved)
        var previous = approved
        for _ in 0..<20 {
            for live in [partial, full] {
                previous = DuoLayoutConfiguration.resolve(live, previous: previous)
                XCTAssertEqual(previous, approved)
                var handoff = live; handoff.hinge.receive(.unavailable)
                previous = DuoLayoutConfiguration.resolve(handoff, previous: previous)
                XCTAssertTrue(previous.isPortrait); XCTAssertTrue(previous.isTransition)
            }
        }
        // The hinge status and division update may arrive in either order.
        partial.hinge.receive(.fullyOpen)
        XCTAssertEqual(DuoLayoutConfiguration.resolve(partial, previous: previous), approved)
        for badDivision in [CGRect(x: 315, y: 0, width: 40, height: 951),
                            CGRect(x: 0, y: 400, width: 669, height: 40),
                            CGRect(x: 0, y: 455.5, width: 334, height: 40),
                            CGRect(x: 0, y: 445.5, width: 669, height: 60)] {
            partial.hinge.receive(.partiallyOpen); partial.divisions = [badDivision]
            XCTAssertFalse(DuoLayoutConfiguration.resolve(partial, previous: approved).isPortrait)
        }
        var landscape = input(.partiallyOpen)
        landscape.bounds.size = CGSize(width: 951, height: 669)
        landscape.safeContent = CGRect(x: 0, y: 0, width: 867, height: 635)
        landscape.railOnRight = true
        landscape.occlusions = [CGRect(x: 867, y: 0, width: 84, height: 124)]
        landscape.divisions = [CGRect(x: 455.5, y: 0, width: 40, height: 669)]
        let expectedPartial = DuoLayoutConfiguration.resolve(landscape)
        XCTAssertEqual(DuoLayoutConfiguration.resolve(landscape, previous: approved), expectedPartial)
        landscape.hinge.receive(.fullyOpen); landscape.divisions = []
        landscape.bounds.size.width = 951
        landscape.safeContent.size.width = 867
        landscape.occlusions = [CGRect(x: 867, y: 0, width: 84, height: 124)]
        XCTAssertEqual(DuoLayoutConfiguration.resolve(landscape, previous: expectedPartial),
                       DuoLayoutConfiguration.resolve(landscape))
    }

    func testPortraitUsesContainerOriginAndAppliesBottomSafeAreaOnce() {
        var i = input()
        i.bounds.origin = CGPoint(x: 17, y: 23)
        i.safeContent = CGRect(x: 17, y: 107, width: 669, height: 833)
        i.occlusions = [CGRect(x: 546, y: 23, width: 140, height: 84)]
        let c = DuoLayoutConfiguration.resolve(i)
        XCTAssertTrue(c.isPortrait)
        XCTAssertEqual(c.map.origin, i.bounds.origin)
        XCTAssertEqual(c.list.minY, 499)
        XCTAssertEqual(c.controls?.maxY, i.bounds.maxY - 24)
        XCTAssertEqual(c.bottomInset, 34)
    }

    func testLandscapePortraitRoundTripDoesNotInheritAPortraitRail() {
        var landscape = input()
        landscape.bounds.size = CGSize(width: 951, height: 669)
        landscape.safeContent = CGRect(x: 0, y: 0, width: 867, height: 635)
        landscape.railOnRight = true
        landscape.occlusions = [CGRect(x: 867, y: 0, width: 84, height: 124)]
        let original = DuoLayoutConfiguration.resolve(landscape)
        var previous = original
        for _ in 0..<20 {
            previous = DuoLayoutConfiguration.resolve(input(), previous: previous)
            XCTAssertTrue(previous.isPortrait)
            previous = DuoLayoutConfiguration.resolve(landscape, previous: previous)
            XCTAssertEqual(previous, original)
        }
    }

    func testRetainedListKeepsAnchorSpacingAndBothPreferencesAcrossRotation() async throws {
        let cities = (0..<20).map { City(name: "City \($0)", timeZoneID: "UTC", canonicalID: "portrait-\($0)") }
        let controller = CityListReorderViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 669, height: 475))
        window.rootViewController = controller; window.isHidden = false
        defer { window.isHidden = true }
        let list = controller.collectionView
        let instant = Date(timeIntervalSince1970: 1793250000)
        for style in [CityViewPreference.basic, .compact] {
            controller.prepareDuoLayout(viewport: window.bounds.size, showsLogo: false, horizontalInset: 104)
            controller.apply(cities: cities, selectedInstant: instant, userCurrentLocationItem: nil,
                             cityViewPreference: style, topInset: 20, bottomInset: 24, cardBackgroundColor: .white)
            list.setContentOffset(.zero, animated: false)
            controller.view.setNeedsLayout(); controller.view.layoutIfNeeded()
            try await Task.sleep(for: .milliseconds(100))
            list.layoutIfNeeded()
            let first = try XCTUnwrap(list.cellForItem(at: IndexPath(item: 0, section: 0)))
            XCTAssertEqual(first.frame, CGRect(x: 104, y: 20, width: 461, height: style == .basic ? 140 : 88))
            XCTAssertEqual(list.contentInsetAdjustmentBehavior, .never)
            XCTAssertEqual(list.adjustedContentInset.bottom, 24)
            XCTAssertTrue(list.visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionHeader).isEmpty)
            list.setContentOffset(CGPoint(x: 0, y: 400), animated: false); list.layoutIfNeeded()
            controller.lastDuoScrollAnchor = controller.captureDuoScrollAnchor()
            let anchor = try XCTUnwrap(controller.lastDuoScrollAnchor)
            let id = try XCTUnwrap(anchor.candidates.first)
            for portrait in [false, true, false, true] {
                let size = portrait ? CGSize(width: 669, height: 475) : CGSize(width: 340, height: 669)
                controller.prepareDuoLayout(viewport: size, showsLogo: !portrait, horizontalInset: portrait ? 104 : 8)
                controller.apply(cities: cities, selectedInstant: instant, userCurrentLocationItem: nil,
                                 cityViewPreference: style, topInset: portrait ? 20 : 25,
                                 bottomInset: portrait ? 24 : 34, cardBackgroundColor: .white)
                window.frame.size = size; controller.view.frame = window.bounds
                controller.view.setNeedsLayout(); controller.view.layoutIfNeeded()
                try await Task.sleep(for: .milliseconds(50))
                list.layoutIfNeeded()
                XCTAssertTrue(controller.collectionView === list)
                let index = try XCTUnwrap(controller.citiesLocal.firstIndex { $0.id == id })
                let frame = try XCTUnwrap(list.layoutAttributesForItem(at: IndexPath(item: index, section: 0))).frame
                XCTAssertEqual(list.contentOffset.y - frame.minY, anchor.offset, accuracy: 0.34)
                XCTAssertEqual(controller.citiesLocal.map(\.id), cities.map(\.id))
                let paths = list.indexPathsForVisibleItems.sorted()
                for (a, b) in zip(paths, paths.dropFirst()) where b.item == a.item + 1 {
                    let first = try XCTUnwrap(list.cellForItem(at: a)), next = try XCTUnwrap(list.cellForItem(at: b))
                    XCTAssertEqual(next.frame.minY - first.frame.maxY, 8, accuracy: 0.34)
                }
            }
            controller.duoScrollAnchor = nil; controller.lastDuoScrollAnchor = nil
        }
    }

    func testPortraitProjectionWrapHitTestingAndRendererSurviveRotation() throws {
        let cities = [City(name: "Bangkok", timeZoneID: "Asia/Bangkok", canonicalID: "portrait-bangkok", latitude: 13.7563, longitude: 100.5018),
                      City(name: "Delhi", timeZoneID: "Asia/Kolkata", canonicalID: "portrait-delhi", latitude: 28.6, longitude: 77.2)]
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 669, height: 951))
        let parent = UIViewController(); window.rootViewController = parent; window.isHidden = false
        defer { window.isHidden = true }
        let map = WorldMapScrollView(frame: CGRect(x: 0, y: 0, width: 527, height: 669))
        parent.view.addSubview(map)
        let model = TimeDialViewModel(); model.tickerTask?.cancel()
        model.beginDialDrag(); model.baseTime = Date(timeIntervalSince1970: 1793250000)
        model.updateDialRotation(-45); model.cancelDialDrag()
        let instant = model.selectedInstant, rotation = model.rotationDegrees
        map.updatePosition(0.61) { _ in }
        map.updateIllumination(at: instant); map.updateNightLights(cities)
        map.updateMarkers(cities, at: instant, timeFormatPreference: "twentyFourHour", localeIdentifier: "en_US")
        map.layoutIfNeeded()
        let overlay = try XCTUnwrap(map.dayNightOverlay), renderer = overlay.renderer
        let markerIDs = map.markers.map(ObjectIdentifier.init)
        XCTAssertFalse(map.markerTap.delegate === map)
        XCTAssertTrue(map.markerTap.delegate === map.markerTapDelegate)
        for index in 0..<20 {
            let previousCenter = map.normalizedCenter
            let portrait = index.isMultiple(of: 2)
            let profile: WorldMapGeometryProfile = portrait ? .duoInnerPortrait : .duoInner
            let size = portrait ? CGSize(width: 669, height: 476) : CGSize(width: 527, height: 669)
            map.updatePresentation(profile: profile, visible: true); map.frame.size = size
            map.layoutIfNeeded()
            let geometry = profile.canvas(in: size)
            XCTAssertEqual(map.normalizedCenter, previousCenter, accuracy: 1e-10)
            XCTAssertEqual(map.repeatedImage.frame, map.repeatedCanvas.frame)
            XCTAssertEqual(map.imageView.frame, map.mapCanvas.bounds)
            XCTAssertTrue(map.dayNightOverlay === overlay); XCTAssertTrue(overlay.renderer === renderer)
            XCTAssertEqual(map.markers.map(ObjectIdentifier.init), markerIDs)
            XCTAssertEqual(map.illuminationInstant, instant)
            XCTAssertEqual(model.selectedInstant, instant); XCTAssertEqual(model.rotationDegrees, rotation)
            XCTAssertEqual(overlay.uniforms.viewport.y, Float(-geometry.top / geometry.side), accuracy: 1e-7)
            XCTAssertEqual(overlay.uniforms.viewport.w, Float(size.height / geometry.side), accuracy: 1e-7)
            for marker in map.markers {
                let point = marker.convert(CGPoint(x: marker.bounds.midX, y: 6), to: map)
                XCTAssertEqual(point.y, geometry.top + marker.normalizedPoint.y * geometry.side, accuracy: 1e-6)
            }
            let dot = try XCTUnwrap(map.hitDots.first)
            let rect = WorldMapPeriodic.nearest(dot.bounds, to: map.bounds.midX, period: geometry.side)
            XCTAssertEqual(map.cityIDs(at: CGPoint(x: rect.midX, y: rect.midY + geometry.top)), [cities[0].id])
            let center = map.normalizedCenter
            map.bounds.origin.x += geometry.side
            map.scrollViewDidScroll(map); map.setNeedsLayout(); map.layoutIfNeeded()
            XCTAssertEqual(map.normalizedCenter, center, accuracy: 0.001)
        }
    }

    func testSharedInstantAndNativeIdentitiesSurvivePortraitLandscapeAndAppearanceChanges() async throws {
        let model = TimeDialViewModel(); model.tickerTask?.cancel()
        let cities = [City(name: "Bangkok", timeZoneID: "Asia/Bangkok", latitude: 13.7563, longitude: 100.5018),
                      City(name: "London", timeZoneID: "Europe/London", latitude: 51.5074, longitude: -0.1278)] +
            (0..<6).map { City(name: "Saved \($0)", timeZoneID: "UTC", canonicalID: "retained-\($0)") }
        let data = try JSONEncoder().encode(cities)
        var writes = 0
        let store = CityStore(storage: .init(read: { _ in data }, write: { _, _ in writes += 1 },
                                            sharedDefaults: { _ in nil }, reloadWidgets: {}))
        let savedOrder = store.cities.map(\.id), initialWrites = writes
        let state = PortraitSynchronizationState(layout: DuoLayoutConfiguration.resolve(input()))
        let host = UIHostingController(rootView: PortraitSynchronizationFixture(state: state, model: model, store: store))
        let window = UIWindow(frame: state.layout.content); window.rootViewController = host; window.isHidden = false
        defer { window.isHidden = true }
        func maps(_ view: UIView) -> [WorldMapScrollView] {
            (view as? WorldMapScrollView).map { [$0] } ?? view.subviews.flatMap { maps($0) }
        }
        func list(_ controller: UIViewController) -> CityListReorderViewController? {
            (controller as? CityListReorderViewController) ?? controller.children.lazy.compactMap { list($0) }.first
        }
        host.view.frame = window.bounds
        host.view.layoutIfNeeded()
        try await Task.sleep(for: .milliseconds(200))
        let originalMap = try XCTUnwrap(maps(host.view).first)
        let originalList = try XCTUnwrap(list(host))
        let overlay = try XCTUnwrap(originalMap.dayNightOverlay)
        let renderer = overlay.renderer
        originalList.collectionView.setContentOffset(CGPoint(x: 0, y: 200), animated: false)
        originalList.collectionView.layoutIfNeeded()
        let scrollAnchor = originalList.captureDuoScrollAnchor()
        model.beginDialDrag(); model.baseTime = Date(timeIntervalSince1970: 1793250000)
        model.updateDialRotation(-30); model.cancelDialDrag()
        try await Task.sleep(for: .milliseconds(100))
        let selected = model.selectedInstant, rotation = model.rotationDegrees, reset = model.resetSignal
        var landscape = input()
        landscape.bounds.size = CGSize(width: 951, height: 669)
        landscape.safeContent = CGRect(x: 0, y: 0, width: 867, height: 635)
        landscape.railOnRight = true
        landscape.occlusions = [CGRect(x: 867, y: 0, width: 84, height: 124)]
        var partialPortrait = input(.partiallyOpen)
        partialPortrait.divisions = [CGRect(x: 0, y: 455.5, width: 669, height: 40)]
        var partialLandscape = landscape; partialLandscape.hinge.receive(.partiallyOpen)
        partialLandscape.divisions = [CGRect(x: 455.5, y: 0, width: 40, height: 669)]
        var fullWithSeam = landscape; fullWithSeam.divisions = partialLandscape.divisions
        var partialWithoutSeam = partialLandscape; partialWithoutSeam.divisions = []
        for nextInput in [partialPortrait, input(), partialPortrait, landscape, fullWithSeam, partialLandscape,
                          fullWithSeam, landscape, partialWithoutSeam, partialLandscape, partialWithoutSeam, landscape, input()] {
            let priorLayout = state.layout
            let wasPortrait = priorLayout.isPortrait
            let priorMapBounds = originalMap.bounds
            let priorMapOffset = originalMap.contentOffset
            let priorListWidth = originalList.collectionView.bounds.width
            let priorListOffset = originalList.collectionView.contentOffset
            let firstItem = IndexPath(item: 0, section: 0)
            let priorCardWidth = originalList.collectionView.layoutAttributesForItem(at: firstItem)?.frame.width
            state.layout = DuoLayoutConfiguration.resolve(nextInput, previous: state.layout)
            state.dark.toggle()
            window.frame = state.layout.content; host.view.frame = window.bounds
            host.view.setNeedsLayout(); host.view.layoutIfNeeded()
            try await Task.sleep(for: .milliseconds(150))
            XCTAssertEqual(maps(host.view).count, 1)
            XCTAssertTrue(maps(host.view).first === originalMap)
            XCTAssertTrue(list(host) === originalList)
            if priorLayout.arrangement == .inner && state.layout.arrangement == .inner {
                XCTAssertEqual(originalMap.bounds, priorMapBounds)
                XCTAssertEqual(originalMap.contentOffset, priorMapOffset)
                XCTAssertNil(originalMap.layer.animation(forKey: "bounds.size"))
                XCTAssertNil(originalMap.layer.animation(forKey: "bounds.origin"))
                XCTAssertNil(originalList.duoScrollAnchor)
                XCTAssertEqual(state.layout.mapDrawingFrame, priorLayout.mapDrawingFrame)
                XCTAssertEqual(state.layout.wheelCenter, priorLayout.wheelCenter)
                XCTAssertEqual(originalList.collectionView.bounds.width, priorListWidth)
                XCTAssertEqual(originalList.collectionView.contentOffset, priorListOffset)
                XCTAssertEqual(originalList.collectionView.layoutAttributesForItem(at: firstItem)?.frame.width, priorCardWidth)
            }
            if wasPortrait && state.layout.isPortrait {
                XCTAssertEqual(originalList.collectionView.contentOffset.y, 200, accuracy: 1)
                XCTAssertEqual(originalList.captureDuoScrollAnchor()?.candidates, scrollAnchor?.candidates)
            }
            XCTAssertTrue(originalMap.dayNightOverlay === overlay); XCTAssertTrue(overlay.renderer === renderer)
            XCTAssertEqual(originalMap.bounds.width, state.layout.mapRenderingViewport.width, accuracy: 1.0 / 3)
            XCTAssertEqual(originalMap.bounds.height, state.layout.mapRenderingViewport.height, accuracy: 1.0 / 3)
            XCTAssertEqual(originalMap.normalizedCenter, 0.61, accuracy: 1e-10)
            XCTAssertEqual(originalMap.lastInstant, selected)
            XCTAssertEqual(originalMap.illuminationInstant, selected)
            XCTAssertEqual(overlay.lastDate, selected)
            XCTAssertEqual(originalList.selectedInstant, selected)
            XCTAssertEqual(model.selectedInstant, selected); XCTAssertEqual(model.rotationDegrees, rotation)
            XCTAssertEqual(model.resetSignal, reset)
            XCTAssertEqual(originalList.citiesLocal.map(\.id), savedOrder)
            XCTAssertEqual(store.cities.map(\.id), savedOrder); XCTAssertEqual(writes, initialWrites)
        }
        model.updateDialRotation(15)
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertNotEqual(model.selectedInstant, selected)
        XCTAssertEqual(originalList.selectedInstant, model.selectedInstant)
        XCTAssertEqual(originalMap.lastInstant, model.selectedInstant)
        XCTAssertEqual(originalMap.illuminationInstant, model.selectedInstant)
        // The retained native map applies the new illumination during layout.
        originalMap.layoutIfNeeded()
        XCTAssertEqual(overlay.lastDate, model.selectedInstant)
    }
}

@MainActor private final class PortraitSynchronizationState: ObservableObject {
    @Published var layout: DuoLayoutConfiguration
    @Published var dark = false
    @Published var position: CGFloat = 0.61
    init(layout: DuoLayoutConfiguration) { self.layout = layout }
}

private struct PortraitSynchronizationFixture: View {
    @ObservedObject var state: PortraitSynchronizationState
    let model: TimeDialViewModel
    let store: CityStore
    var body: some View {
        TimeDialObservedContent(viewModel: model) { instant, _, _, _, _, _ in
            let layout = state.layout
            ZStack(alignment: .topLeading) {
                WorldMapObservedContent(viewModel: model, cityStore: store, viewportSize: layout.mapRenderingViewport.size,
                                        horizontalPosition: $state.position, geometryProfile: layout.mapGeometryProfile,
                                        visualViewport: layout.mapVisualViewport, usesDuoDrawingContainer: true,
                                        interactionViewport: layout.mapInteractionViewport)
                    .position(x: layout.mapDrawingFrame.midX, y: layout.mapDrawingFrame.midY)
                CityListReorderUIKitView(cities: .constant(store.cities), selectedInstant: instant,
                                        userCurrentLocationItem: nil, topSafeAreaInset: layout.listTopInset,
                                        bottomContentInset: layout.bottomInset, onRenameRequested: { _ in }, onCitySelected: { _ in },
                                        duoViewport: layout.list.size, duoShowsLogo: !layout.isPortrait,
                                        duoHorizontalInset: layout.listHorizontalInset)
                    .frame(width: layout.list.width, height: layout.list.height)
                    .position(x: layout.list.midX, y: layout.list.midY)
            }
            .frame(width: layout.content.width, height: layout.content.height)
        }
        .environment(\.appTheme, state.dark ? .dark : .light)
        .environment(\.colorScheme, state.dark ? .dark : .light)
        .ignoresSafeArea()
    }
}
