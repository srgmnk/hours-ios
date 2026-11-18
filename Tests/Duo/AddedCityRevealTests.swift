import XCTest
import SwiftUI
@testable import MapHarness

@MainActor final class AddedCityRevealTests: XCTestCase {
    private let instant = Date(timeIntervalSince1970: 1793250000)
    private let modes: [CityViewPreference] = [.basic, .compact, .cards]

    private func cities(_ count: Int) -> [City] {
        (0..<count).map { City(name: "City \($0)", timeZoneID: "UTC", canonicalID: "reveal-\($0)") }
    }

    private func apply(_ controller: CityListReorderViewController, _ cities: [City],
                       mode: CityViewPreference, bottom: CGFloat = 130,
                       instant: Date? = nil) {
        controller.apply(cities: cities, selectedInstant: instant ?? self.instant,
                         userCurrentLocationItem: nil, cityViewPreference: mode,
                         topInset: 25, bottomInset: bottom, cardBackgroundColor: .white)
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        controller.collectionView.layoutIfNeeded()
    }

    private func waitForReveal(_ controller: CityListReorderViewController,
                               _ request: AddedCityRevealRequest) async {
        let finished = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            request.cityID == nil && !controller.isRevealingAddedCity
        }, object: nil)
        await fulfillment(of: [finished], timeout: 4)
        controller.collectionView.layoutIfNeeded()
    }

    private func assertVisible(_ index: Int, in controller: CityListReorderViewController,
                               file: StaticString = #filePath, line: UInt = #line) throws {
        let list = controller.collectionView
        let path = IndexPath(item: index, section: 0)
        let frame = try XCTUnwrap(list.layoutAttributesForItem(at: path), file: file, line: line).frame
        XCTAssertNotNil(list.cellForItem(at: path), file: file, line: line)
        let visible = list.bounds.inset(by: list.adjustedContentInset).insetBy(dx: -1, dy: -1)
        XCTAssertTrue(visible.contains(frame), "City \(index): \(frame), viewport: \(visible)", file: file, line: line)
        if controller.cityViewPreference == .cards, index % 2 == 1 {
            let partner = try XCTUnwrap(list.layoutAttributesForItem(at: IndexPath(item: index - 1, section: 0)))
            XCTAssertEqual(partner.frame.minY, frame.minY, file: file, line: line)
            XCTAssertTrue(visible.contains(partner.frame), file: file, line: line)
        }
    }

    func testLongListsRevealOddAndEvenAdditionsAcrossModesDuoLayoutsAndAppearances() async throws {
        func duo(_ status: DuoHingeState.Status, _ width: CGFloat, _ height: CGFloat,
                 rail: Bool?) -> DuoLayoutConfiguration {
            var hinge = DuoHingeState(); hinge.receive(status)
            let portrait = rail == nil
            return .resolve(.init(hinge: hinge, bounds: CGRect(x: 0, y: 0, width: width, height: height),
                safeContent: portrait ? CGRect(x: 0, y: 84, width: width, height: height - 84) :
                    CGRect(x: rail == false ? 84 : 0, y: 0, width: width - 84, height: height - 34),
                railOnRight: rail, occlusions: [], divisions: []))
        }
        let layouts: [(CGSize, DuoLayoutConfiguration?)] = [
            (CGSize(width: 393, height: 852), nil),
            (CGSize(width: 852, height: 393), nil)
        ] + [
            duo(.closed, 466, 678, rail: true),
            duo(.closed, 678, 466, rail: true),
            duo(.fullyOpen, 951, 669, rail: true),
            duo(.partiallyOpen, 800, 669, rail: true),
            duo(.fullyOpen, 669, 951, rail: nil),
            duo(.partiallyOpen, 669, 951, rail: nil),
            duo(.fullyOpen, 469, 669, rail: false),
            duo(.fullyOpen, 469, 669, rail: true)
        ].map { ($0.listViewport.size, Optional($0)) }
        let fixture = try RevealFixture()
        defer { fixture.close() }
        for appearance in [UIUserInterfaceStyle.light, .dark] {
            fixture.window.overrideUserInterfaceStyle = appearance
            for (size, layout) in layouts {
                for mode in modes {
                    let controller = fixture.replaceController(size: size)
                    controller.updateCardTheme(appearance == .dark ? .dark : .light)
                    controller.prepareDuoLayout(viewport: layout == nil ? nil : size,
                        showsLogo: !(layout?.isPortrait ?? false),
                        horizontalInset: layout?.listHorizontalInset ?? 8)
                    let bottom = layout.map { $0.isInner ? $0.bottomInset : 130 } ?? 130
                    apply(controller, cities(24), mode: mode, bottom: bottom)
                    let originalInset = controller.collectionView.contentInset
                    for count in [25, 26] {
                        // First from the top, then from near the bottom, with the
                        // second Cards addition sharing the already visible row.
                        let added = cities(count)
                        apply(controller, added, mode: mode, bottom: bottom)
                        let request = AddedCityRevealRequest(cityID: added.last!.id, mode: mode)
                        controller.receiveAddedCityReveal(request)
                        controller.view.layoutIfNeeded()
                        await waitForReveal(controller, request)
                        try assertVisible(count - 1, in: controller)
                        XCTAssertEqual(controller.citiesLocal.map(\.id), added.map(\.id))
                        XCTAssertEqual(controller.citiesLocal.primaryCity?.id, added.first?.id)
                        XCTAssertEqual(controller.collectionView.contentInset, originalInset)
                        XCTAssertNil(request.cityID)
                    }
                }
            }
        }
    }

    func testFirstAndShortListAdditionsAlreadyFullyVisibleDoNotScroll() async throws {
        let fixture = try RevealFixture()
        defer { fixture.close() }
        for mode in modes {
            let controller = fixture.replaceController(size: CGSize(width: 393, height: 852))
            apply(controller, [], mode: mode)
            for count in 1...2 {
                let added = cities(count)
                apply(controller, added, mode: mode)
                let offset = controller.collectionView.contentOffset
                let request = AddedCityRevealRequest(cityID: added.last!.id, mode: mode)
                controller.receiveAddedCityReveal(request)
                controller.view.layoutIfNeeded()
                XCTAssertNil(request.cityID)
                XCTAssertFalse(controller.isRevealingAddedCity)
                XCTAssertEqual(controller.collectionView.contentOffset, offset)
                try assertVisible(count - 1, in: controller)
            }
        }
    }

    func testRequestWaitsForAttachmentAndMatchingDuoViewportThenIsConsumedOnce() async throws {
        let controller = CityListReorderViewController()
        controller.loadViewIfNeeded()
        let viewport = CGSize(width: 340, height: 669)
        controller.prepareDuoLayout(viewport: viewport)
        apply(controller, cities(31), mode: .cards, bottom: 34)
        let request = AddedCityRevealRequest(cityID: cities(31).last!.id, mode: .cards)
        controller.receiveAddedCityReveal(request)
        controller.view.layoutIfNeeded()
        XCTAssertNotNil(request.cityID)
        let fixture = try RevealFixture()
        defer { fixture.close() }
        fixture.mount(controller, size: CGSize(width: 455, height: 669))
        controller.view.layoutIfNeeded()
        XCTAssertNotNil(request.cityID, "Do not reveal against an obsolete pane size")
        controller.view.frame.size = viewport
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        await waitForReveal(controller, request)
        try assertVisible(30, in: controller)
        // The next Duo resize must preserve the new position, not the old top anchor.
        controller.prepareDuoLayout(viewport: CGSize(width: 382, height: 678))
        controller.view.frame.size = CGSize(width: 382, height: 678)
        controller.view.setNeedsLayout(); controller.view.layoutIfNeeded()
        XCTAssertGreaterThan(controller.collectionView.contentOffset.y, 0)
        let replacement = fixture.replaceController(size: viewport)
        apply(replacement, cities(31), mode: .cards)
        let offset = replacement.collectionView.contentOffset
        replacement.receiveAddedCityReveal(request)
        replacement.view.layoutIfNeeded()
        XCTAssertEqual(replacement.collectionView.contentOffset, offset, "A consumed request cannot replay on remount")
    }

    func testCancelledMissingHiddenChangedModeAndUserInterruptedRequestsNeverReplay() throws {
        let fixture = try RevealFixture()
        defer { fixture.close() }
        for reason in ["cancel", "missing", "hidden", "mode", "drag", "reorder"] {
            let controller = fixture.replaceController(size: CGSize(width: 393, height: 852))
            apply(controller, cities(30), mode: .basic)
            let request = AddedCityRevealRequest(cityID: reason == "missing" ? "removed" : "reveal-29", mode: .basic)
            controller.receiveAddedCityReveal(request, isListVisible: reason != "hidden")
            switch reason {
            case "cancel": request.cancel()
            case "mode": apply(controller, cities(30), mode: .compact)
            case "drag": controller.scrollViewWillBeginDragging(controller.collectionView)
            case "reorder": controller.isReordering = true
            default: break
            }
            controller.view.layoutIfNeeded()
            XCTAssertNil(request.cityID, reason)
            XCTAssertFalse(controller.isRevealingAddedCity, reason)
            controller.isReordering = false
            apply(controller, cities(30), mode: .basic)
            let offset = controller.collectionView.contentOffset
            controller.receiveAddedCityReveal(request)
            controller.view.layoutIfNeeded()
            XCTAssertEqual(controller.collectionView.contentOffset, offset, reason)
        }
    }

    func testDataUpdatesWithoutAnInsertionRequestNeverRevealTheLastCity() throws {
        let fixture = try RevealFixture()
        defer { fixture.close() }
        for mode in modes {
            let controller = fixture.replaceController(size: CGSize(width: 393, height: 852))
            var saved = cities(30)
            apply(controller, saved, mode: mode)
            let list = controller.collectionView
            list.scrollToItem(at: IndexPath(item: 10, section: 0), at: .top, animated: false)
            list.layoutIfNeeded()
            // Self-sizing reloads may adjust contentOffset while preserving the visible city.
            let anchor = try XCTUnwrap(list.indexPathsForVisibleItems.min { $0.item < $1.item })
            let anchorID = saved[anchor.item].id
            let anchorOffset = try XCTUnwrap(list.layoutAttributesForItem(at: anchor)).frame.minY - list.bounds.minY
            // Reload, time/weather reconfiguration, rename, reorder/Primary,
            // deletion, and even an external append carry no Add City request.
            for mutation in 0..<6 {
                switch mutation {
                case 2: saved[4].customDisplayName = "Renamed"
                case 3: saved.swapAt(0, 1)
                case 4: saved.removeLast()
                case 5: saved.append(cities(31).last!)
                default: break
                }
                apply(controller, saved, mode: mode, instant: instant.addingTimeInterval(Double(mutation) * 60))
                controller.receiveAddedCityReveal(nil)
                controller.view.layoutIfNeeded()
                let anchorIndex = try XCTUnwrap(saved.firstIndex { $0.id == anchorID })
                let anchorFrame = try XCTUnwrap(list.layoutAttributesForItem(at: IndexPath(item: anchorIndex, section: 0))).frame
                XCTAssertEqual(anchorFrame.minY - list.bounds.minY, anchorOffset, accuracy: 1,
                               "Mode: \(mode), mutation: \(mutation)")
                XCTAssertFalse(list.indexPathsForVisibleItems.contains(IndexPath(item: saved.count - 1, section: 0)))
                XCTAssertFalse(controller.isRevealingAddedCity)
            }
        }
    }
}

@MainActor private final class RevealFixture {
    let window: UIWindow
    let parent = UIViewController()
    let previous: UIWindow?

    init() throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        previous = scene.windows.first(where: \.isKeyWindow)
        window = UIWindow(windowScene: scene)
        window.rootViewController = parent
        window.makeKeyAndVisible()
        parent.view.layoutIfNeeded()
    }

    func mount(_ controller: CityListReorderViewController, size: CGSize) {
        parent.addChild(controller)
        parent.view.addSubview(controller.view)
        controller.view.frame = CGRect(origin: .zero, size: size)
        controller.didMove(toParent: parent)
    }

    func replaceController(size: CGSize) -> CityListReorderViewController {
        for child in parent.children {
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
        let controller = CityListReorderViewController()
        mount(controller, size: size)
        return controller
    }

    func close() {
        window.isHidden = true
        previous?.makeKeyAndVisible()
    }
}
