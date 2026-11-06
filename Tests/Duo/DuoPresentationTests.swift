import XCTest
import SwiftUI
@testable import MapHarness

@MainActor final class DuoPresentationTests: XCTestCase {
    func testDuoDrawingContainerKeepsNativeViewAcrossFolding() async throws {
        let state = DuoDrawingTestState()
        let controller = UIHostingController(rootView: DuoDrawingTestView(state: state))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 466, height: 678))
        window.rootViewController = controller; window.isHidden = false
        defer { window.isHidden = true }
        func findMap(_ view: UIView) -> WorldMapScrollView? {
            if let map = view as? WorldMapScrollView { return map }
            return view.subviews.lazy.compactMap { findMap($0) }.first
        }
        controller.view.layoutIfNeeded()
        try await Task.sleep(for: .milliseconds(100))
        let original = try XCTUnwrap(findMap(controller.view))
        let renderer = try XCTUnwrap(original.dayNightOverlay)
        for _ in 0..<12 {
            state.inner.toggle()
            window.frame.size = state.inner ? CGSize(width: 951, height: 669) : CGSize(width: 466, height: 678)
            controller.view.frame = window.bounds
            controller.view.setNeedsLayout(); controller.view.layoutIfNeeded()
            try await Task.sleep(for: .milliseconds(50))
            let current = try XCTUnwrap(findMap(controller.view))
            XCTAssertTrue(current === original)
            XCTAssertTrue(current.dayNightOverlay === renderer)
            XCTAssertEqual(current.bounds.width, state.inner ? 527 : 382)
            XCTAssertEqual(current.clipsToBounds, state.inner)
            XCTAssertEqual(current.normalizedCenter, 0.314159, accuracy: 1e-10)
            XCTAssertEqual(renderer.frame.width, state.inner ? 527 : 466)
        }
    }

    func testOuterVisualOverflowPreservesProjectionMarkersAndHitTesting() throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 466, height: 678))
        let controller = UIViewController(); window.rootViewController = controller; window.isHidden = false
        defer { window.isHidden = true }
        let map = WorldMapScrollView(frame: CGRect(x: 0, y: 0, width: 382, height: 678))
        controller.view.addSubview(map)
        let instant = Date(timeIntervalSince1970: 1793160000)
        map.updatePosition(0.7356067316209035) { _ in }
        map.updateIllumination(at: instant)
        map.updateMarkers([City(name: "Bangkok", timeZoneID: "Asia/Bangkok", canonicalID: "bangkok-th", latitude: 13.7563, longitude: 100.5018)],
                          at: instant, timeFormatPreference: "twentyFourHour", localeIdentifier: "en_US")
        map.layoutIfNeeded()
        // Record UIKit's pixel-rounded camera as a real drag would before
        // checking hundreds of exact longitude-cycle translations.
        map.scrollViewDidScroll(map)
        let canvas = map.repeatedImage.frame, offset = map.contentOffset
        let markers = map.markers.map(\.frame)
        XCTAssertFalse(markers.isEmpty)
        let overlay = try XCTUnwrap(map.dayNightOverlay)
        let side = map.mapCanvas.bounds.width
        let center = map.normalizedCenter
        for visualX: CGFloat in [0, -84] {
            let visual = CGRect(x: visualX, y: 0, width: 466, height: 678)
            map.updatePresentation(profile: .conventional, visible: true, visualViewport: visual)
            map.layoutIfNeeded()
            XCTAssertFalse(map.clipsToBounds)
            XCTAssertEqual(map.bounds.size, CGSize(width: 382, height: 678))
            XCTAssertEqual(map.repeatedImage.frame, canvas)
            XCTAssertEqual(map.repeatedCanvas.frame, canvas)
            XCTAssertEqual(map.contentOffset.x, offset.x, accuracy: 1e-8)
            XCTAssertEqual(map.contentOffset.y, offset.y)
            XCTAssertEqual(map.markers.map(\.frame), markers)
            XCTAssertTrue(map.dayNightOverlay === overlay)
            XCTAssertEqual(overlay.frame, visual.offsetBy(dx: map.bounds.minX, dy: 0))
            XCTAssertEqual(overlay.uniforms.viewport.z, Float(466 / side), accuracy: 1e-7)
            let expectedOrigin = SolarPosition.wrap(Double((map.bounds.minX + visualX) / side), period: 1)
            XCTAssertEqual(overlay.uniforms.viewport.x, Float(expectedOrigin), accuracy: 1e-7)
            let outside = CGPoint(x: map.bounds.minX + (visualX == 0 ? 420 : -40), y: 300)
            XCTAssertNil(map.hitTest(outside, with: nil), "Decorative overflow must not expand the native touch region")
            for direction: CGFloat in [1, -1] {
                for _ in 0..<100 {
                    map.bounds.origin.x += direction * side
                    map.scrollViewDidScroll(map); map.setNeedsLayout(); map.layoutIfNeeded()
                    XCTAssertEqual(map.normalizedCenter, center, accuracy: 1e-10)
                    XCTAssertEqual(overlay.frame.minX, map.bounds.minX + visualX, accuracy: 1e-8)
                    XCTAssertEqual(map.repeatedImage.frame, map.repeatedCanvas.frame)
                }
            }
        }
        map.updatePresentation(profile: .conventional, visible: true)
        map.layoutIfNeeded()
        XCTAssertTrue(map.clipsToBounds)
        XCTAssertEqual(overlay.frame, map.bounds)
        XCTAssertEqual(map.normalizedCenter, center, accuracy: 1e-10)
    }

    func testRetainedMapKeepsGeographicCenterAndRendererAcrossProfiles() throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 527, height: 669))
        let controller = UIViewController(); window.rootViewController = controller; window.isHidden = false
        defer { window.isHidden = true }
        let map = WorldMapScrollView(frame: window.bounds); controller.view.addSubview(map)
        let instant = Date(timeIntervalSince1970: 1793160000)
        map.updatePosition(0.314159) { _ in }
        map.updateIllumination(at: instant); map.layoutIfNeeded()
        let overlay = try XCTUnwrap(map.dayNightOverlay)
        for i in 0..<30 {
            let sizes = [CGSize(width: 527, height: 669), CGSize(width: 455.5, height: 669), CGSize(width: 382, height: 678), CGSize(width: 455.5, height: 669)]
            let size = sizes[i % sizes.count]
            let profile: WorldMapGeometryProfile = size.height == 669 ? .duoInner : .duoOuter
            map.updatePresentation(profile: profile, visible: true)
            map.frame = CGRect(origin: .zero, size: size); map.setNeedsLayout(); map.layoutIfNeeded()
            XCTAssertEqual(map.normalizedCenter, 0.314159, accuracy: 1e-10)
            XCTAssertTrue(map.dayNightOverlay === overlay)
            XCTAssertEqual(map.repeatedImage.frame, map.repeatedCanvas.frame)
            XCTAssertEqual(map.mapCanvas.bounds.width, profile.canvas(in: size).side)
            XCTAssertEqual(overlay.uniforms.viewport.y, Float(-map.repeatedImage.frame.minY / map.mapCanvas.bounds.width), accuracy: 1e-7)
            map.updatePresentation(profile: profile, visible: false)
            XCTAssertTrue(overlay.isHidden); XCTAssertFalse(overlay.isSuspended)
            map.updatePresentation(profile: profile, visible: true)
            map.updateIllumination(at: instant.addingTimeInterval(Double(i) * 3600)); map.layoutIfNeeded()
            XCTAssertFalse(overlay.isHidden); XCTAssertEqual(overlay.lastDate, map.illuminationInstant)
        }
    }

    func testListAnchorUsesCityIdentityAndSurvivesDeletion() async throws {
        let cities = (0..<20).map { City(name: "City \($0)", timeZoneID: "UTC", canonicalID: "duo-test-\($0)") }
        let controller = CityListReorderViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 382, height: 678))
        window.rootViewController = controller; window.isHidden = false
        defer { window.isHidden = true }
        controller.prepareDuoLayout(viewport: window.bounds.size)
        controller.apply(cities: cities, selectedInstant: Date(timeIntervalSince1970: 1793160000), userCurrentLocationItem: nil, cityViewPreference: .basic, topInset: 25, bottomInset: 130, cardBackgroundColor: .white)
        try await Task.sleep(for: .milliseconds(50))
        controller.view.layoutIfNeeded()
        let list = controller.collectionView
        list.setContentOffset(CGPoint(x: 0, y: 400), animated: false); list.layoutIfNeeded()
        controller.lastDuoScrollAnchor = controller.captureDuoScrollAnchor()
        let anchor = try XCTUnwrap(controller.lastDuoScrollAnchor)
        let id = try XCTUnwrap(anchor.candidates.first)
        for i in 0..<20 {
            let sizes = [CGSize(width: 340, height: 669), CGSize(width: 391.5, height: 669), CGSize(width: 382, height: 678), CGSize(width: 391.5, height: 669)]
            let size = sizes[i % sizes.count]
            controller.prepareDuoLayout(viewport: size)
            window.frame.size = size; controller.view.frame = window.bounds
            controller.view.setNeedsLayout(); controller.view.layoutIfNeeded()
            try await Task.sleep(for: .milliseconds(20))
            let index = try XCTUnwrap(controller.citiesLocal.firstIndex { $0.id == id })
            let frame = try XCTUnwrap(list.layoutAttributesForItem(at: IndexPath(item: index, section: 0)))
            XCTAssertEqual(list.contentOffset.y - frame.frame.minY, anchor.offset, accuracy: 0.34)
            XCTAssertEqual(frame.frame.height, 140, accuracy: 0.34)
        }
        let survivors = cities.filter { $0.id != id }
        controller.prepareDuoLayout(viewport: CGSize(width: 340, height: 669))
        controller.apply(cities: survivors, selectedInstant: Date(), userCurrentLocationItem: nil, cityViewPreference: .basic, topInset: 25, bottomInset: 34, cardBackgroundColor: .white)
        controller.view.frame.size = CGSize(width: 340, height: 669)
        controller.view.setNeedsLayout(); controller.view.layoutIfNeeded()
        XCTAssertTrue(list.contentOffset.y.isFinite)
        XCTAssertEqual(controller.citiesLocal.map(\.id), survivors.map(\.id))
    }
}

@MainActor private final class DuoDrawingTestState: ObservableObject {
    @Published var inner = false
    @Published var position: CGFloat = 0.314159
}

private struct DuoDrawingTestView: View {
    @ObservedObject var state: DuoDrawingTestState
    var body: some View {
        WorldMapView(
            viewportSize: state.inner ? CGSize(width: 527, height: 669) : CGSize(width: 382, height: 678),
            horizontalPosition: $state.position, cities: [], selectedInstant: Date(timeIntervalSince1970: 1793160000),
            geometryProfile: state.inner ? .duoInner : .conventional,
            visualViewport: state.inner ? nil : CGRect(x: 0, y: 0, width: 466, height: 678),
            usesDuoDrawingContainer: true
        )
    }
}
