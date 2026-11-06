import XCTest
import SwiftUI
@testable import MapHarness

@MainActor final class WorldMapInteractionTests: XCTestCase {
    private let instant = Date(timeIntervalSince1970: 1793250000)
    private func city(_ id: String, _ longitude: Double = 77.2, name: String? = nil) -> City {
        City(name: name ?? id, timeZoneID: "Asia/Kolkata", canonicalID: id, latitude: 28.6, longitude: longitude)
    }
    private func map(_ cities: [City], profile: WorldMapGeometryProfile = .conventional,
                     size: CGSize = CGSize(width: 393, height: 852)) -> WorldMapScrollView {
        let map = WorldMapScrollView(frame: CGRect(origin: .zero, size: size))
        map.updatePresentation(profile: profile, visible: true)
        map.updatePosition((77.2 + 180) / 360) { _ in }
        update(map, cities)
        map.layoutIfNeeded()
        return map
    }
    private func update(_ map: WorldMapScrollView, _ cities: [City]) {
        map.updateMarkers(cities, at: instant, timeFormatPreference: "twentyFourHour", localeIdentifier: "en_US")
    }
    private func point(_ rect: CGRect, in map: WorldMapScrollView) -> CGPoint {
        let rect = WorldMapPeriodic.nearest(rect, to: map.bounds.midX, period: map.mapCanvas.bounds.width)
        return CGPoint(x: rect.midX, y: rect.midY + map.repeatedCanvas.frame.minY)
    }

    func testSingleDotAndPlacedLabelSelectSameIdentityWithoutChangingLayoutOrTime() throws {
        let saved = city("delhi"), map = map([city("delhi")])
        let geometry = map.markers.map(\.frame), placement = map.placementOffsets
        let position = map.contentOffset
        var selected: [City.ID] = []
        map.onCitiesSelected = { selected = $0 }
        for target in [map.hitDots[0], map.hitLabels[0]] {
            let ids = map.cityIDs(at: point(target.bounds, in: map))
            XCTAssertEqual(ids, [saved.id]); XCTAssertTrue(map.activateCities(ids))
            XCTAssertEqual(selected, [saved.id])
        }
        XCTAssertEqual(map.markers.map(\.frame), geometry)
        XCTAssertEqual(map.placementOffsets, placement)
        XCTAssertEqual(map.contentOffset, position); XCTAssertEqual(map.lastInstant, instant)
        XCTAssertTrue(map.delaysContentTouches); XCTAssertTrue(map.canCancelContentTouches)
        XCTAssertFalse(map.markerTap.cancelsTouchesInView)
    }

    func testAuthoritativeGroupIncludesTruncatedCustomNamesAndStableOrder() throws {
        var cities = [city("first"), city("second", 77.3), city("third", 77.4), city("fourth", 77.5)]
        cities[0].customDisplayName = String(repeating: "Custom name ", count: 20)
        let map = map(cities)
        XCTAssertEqual(map.sharedLabels.count, 1)
        XCTAssertTrue(map.sharedLabels[0].nameLabel.attributedText!.string.contains("+3"))
        XCTAssertEqual(map.cityIDs(at: point(map.hitLabels[0].bounds, in: map)), cities.map(\.id))
        cities.reverse(); cities[0].customDisplayName = "Renamed"
        update(map, cities)
        XCTAssertEqual(map.sharedLabels[0].cityIDs, cities.map(\.id))
        XCTAssertEqual(map.sharedLabels[0].fullNames, cities.map(\.displayName))
        let stale = map.sharedLabels[0].cityIDs
        update(map, [cities[1]])
        var selected: [City.ID] = []; map.onCitiesSelected = { selected = $0 }
        XCTAssertTrue(map.activateCities(stale)); XCTAssertEqual(selected, [cities[1].id])
        update(map, []); XCTAssertFalse(map.activateCities(stale)); XCTAssertTrue(map.hitLabels.isEmpty)
    }

    func testDistinctDotsInSharedLabelRemainIndividuallySelectable() {
        // Approximately 22 points apart, sharing a label but not visible dots.
        let cities = [city("west", 74), city("east", 81)]
        let map = map(cities)
        XCTAssertEqual(map.sharedLabels.count, 1)
        for (index, dot) in map.hitDots.enumerated() {
            XCTAssertEqual(map.cityIDs(at: point(dot.bounds, in: map)), [cities[index].id])
        }
    }

    func testOverlappingDotsAndEqualDistanceNeverChooseByZOrder() {
        let map = map([city("A"), city("B"), city("unrelated", 90)])
        XCTAssertEqual(map.cityIDs(at: point(map.hitDots[0].bounds, in: map)), ["A", "B"])
        let dots: [WorldMapHitTesting.Target] = [
            .init(cityIDs: ["A"], bounds: CGRect(x: 94, y: 94, width: 12, height: 12)),
            .init(cityIDs: ["B"], bounds: CGRect(x: 114, y: 94, width: 12, height: 12))]
        func hit(_ point: CGPoint, _ labels: [WorldMapHitTesting.Target] = []) -> [String] {
            WorldMapHitTesting.cityIDs(at: point, dots: dots, labels: labels, period: 1000)
        }
        XCTAssertEqual(hit(CGPoint(x: 110, y: 100)), ["A", "B"])
        XCTAssertEqual(hit(CGPoint(x: 106, y: 110)), ["A"])
        XCTAssertEqual(hit(CGPoint(x: 110, y: 120)), [])
        let label = WorldMapHitTesting.Target(cityIDs: ["label"], bounds: CGRect(x: 103, y: 108, width: 15, height: 8))
        XCTAssertEqual(hit(CGPoint(x: 106, y: 110), [label]), ["label"])
        // Actual dot ink always wins over an unrelated label's bounding box.
        XCTAssertEqual(hit(CGPoint(x: 100, y: 100), [.init(cityIDs: ["label"], bounds: CGRect(x: 90, y: 90, width: 20, height: 20))]), ["A"])
    }

    func testPeriodicCopiesDateLineAndRepeatedRecentering() {
        let cities = [city("east", 179.8), city("west", -179.8)]
        let map = map(cities)
        map.updatePosition(0.999) { _ in }; map.layoutIfNeeded()
        XCTAssertEqual(map.sharedLabels.count, 1)
        let cached = map.hitLabels.map(\.bounds)
        for i in 0..<200 {
            map.bounds.origin.x += (i.isMultiple(of: 2) ? 1 : -1) * map.mapCanvas.bounds.width
            map.scrollViewDidScroll(map); map.setNeedsLayout(); map.layoutIfNeeded()
            XCTAssertEqual(map.cityIDs(at: point(map.hitDots[0].bounds, in: map)), cities.map(\.id))
            XCTAssertEqual(map.cityIDs(at: point(map.hitLabels[0].bounds, in: map)), cities.map(\.id))
            XCTAssertEqual(map.hitLabels.map(\.bounds), cached)
        }
    }

    func testDuoProfilesVisibilityAndAdjacentPaneBoundaries() {
        for (profile, size) in [(WorldMapGeometryProfile.conventional, CGSize(width: 402, height: 874)),
                                 (.duoOuter, CGSize(width: 382, height: 678)),
                                 (.duoInner, CGSize(width: 527, height: 669)),
                                 (.duoInner, CGSize(width: 455.5, height: 669))] {
            let map = map([city("A")], profile: profile, size: size)
            XCTAssertEqual(map.cityIDs(at: point(map.hitDots[0].bounds, in: map)), ["A"])
            XCTAssertTrue(map.cityIDs(at: CGPoint(x: map.bounds.maxX + 1, y: 300)).isEmpty)
            map.updatePresentation(profile: profile, visible: false)
            XCTAssertTrue(map.cityIDs(at: point(map.hitDots[0].bounds, in: map)).isEmpty)
            XCTAssertFalse(map.activateCities(["A"]))
        }
    }

    func testAccessibilityActivationAndNoDecorativeCopies() throws {
        let map = map([city("A"), city("B")])
        let elements = try XCTUnwrap(map.accessibilityElements as? [WorldMapAccessibilityElement])
        XCTAssertEqual(elements.count, 3) // Two distinct saved cities and their chooser.
        var selected: [City.ID] = []; map.onCitiesSelected = { selected = $0 }
        for element in elements {
            XCTAssertEqual(element.accessibilityTraits, .button)
            if element.accessibilityLabel == "A, B" {
                XCTAssertFalse(element.accessibilityActivate(), "An unmounted chooser must fail safely")
            } else { XCTAssertTrue(element.accessibilityActivate()) }
        }
        XCTAssertEqual(selected, ["B"])
        map.updatePosition(0.1) { _ in }; map.layoutIfNeeded()
        XCTAssertTrue(map.accessibilityElements!.isEmpty)
    }

    func testDuplicateMenuNamesUseExistingMetadata() {
        let cities = [city("A", 77.2, name: "Same"), city("B", 78, name: "Same")]
        let titles = cities.map { WorldMapCitySelection.title(for: $0, among: cities) }
        XCTAssertNotEqual(titles[0], titles[1]); XCTAssertTrue(titles[0].contains("Asia/Kolkata"))
        XCTAssertEqual(WorldMapCitySelection.title(for: cities[0], among: [cities[0]]), "Same")
    }
    func testRepeatedChooserDismissalKeepsMainThreadAndMapResponsive() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        let host = UIViewController()
        window.rootViewController = host; window.makeKeyAndVisible()
        defer { window.isHidden = true }
        let map = map([city("A"), city("B")])
        host.view.addSubview(map)
        for _ in 0..<3 {
            XCTAssertTrue(map.activateCities(["A", "B"]))
            try await Task.sleep(for: .milliseconds(400))
            let chooser = try XCTUnwrap(host.presentedViewController as? UIAlertController)
            XCTAssertEqual(chooser.actions.compactMap(\.title), ["A", "B", "Cancel"])
            await withCheckedContinuation { continuation in
                chooser.dismiss(animated: false) { continuation.resume() }
            }
            try await Task.sleep(for: .milliseconds(20))
            XCTAssertNil(host.presentedViewController)
            XCTAssertTrue(map.isUserInteractionEnabled)
            XCTAssertTrue(map.isScrollEnabled)
            map.contentOffset.x += 30
            map.layoutIfNeeded()
        }
    }

}
