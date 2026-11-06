import XCTest
import SwiftUI
@testable import MapHarness

@MainActor final class WorldMapAlignmentTests: XCTestCase {
    private let instant = Date(timeIntervalSince1970: 1793250000)
    private var southernCities: [City] {
        [City(name: "Sydney", timeZoneID: "Australia/Sydney", canonicalID: "align-sydney", latitude: -33.8688, longitude: 151.2093),
         City(name: "Melbourne", timeZoneID: "Australia/Melbourne", canonicalID: "align-melbourne", latitude: -37.8136, longitude: 144.9631),
         City(name: "Cape Town", timeZoneID: "Africa/Johannesburg", canonicalID: "align-cape-town", latitude: -33.9249, longitude: 18.4241),
         City(name: "Buenos Aires", timeZoneID: "America/Argentina/Buenos_Aires", canonicalID: "align-buenos-aires", latitude: -34.6037, longitude: -58.3816),
         City(name: "Auckland", timeZoneID: "Pacific/Auckland", canonicalID: "align-auckland", latitude: -36.8485, longitude: 174.7633)]
    }

    func testOuterUsesApprovedInnerLatitudeWithoutChangingScale() {
        let viewport = CGSize(width: 527, height: 669)
        let inner = WorldMapGeometryProfile.duoInner.canvas(in: viewport)
        let centerY = (viewport.height / 2 - inner.top) / inner.side
        let latitude = atan(sinh(.pi * (1 - 2 * centerY))) * 180 / .pi
        // Recorded from the approved fully open native map, not a screenshot offset.
        XCTAssertEqual(latitude, 26.951242272657836, accuracy: 1e-10)
        for size in [CGSize(width: 382, height: 678), CGSize(width: 455.667, height: 669), CGSize(width: 867, height: 587)] {
            let outer = WorldMapGeometryProfile.duoOuter.canvas(in: size)
            let conventional = WorldMapGeometryProfile.conventional.canvas(in: size)
            XCTAssertEqual(outer.side, conventional.side)
            let actualLatitude = atan(sinh(.pi * (1 - 2 * (size.height / 2 - outer.top) / outer.side))) * 180 / .pi
            XCTAssertEqual(actualLatitude, latitude, accuracy: 1e-10)
        }
    }

    func testOuterArtworkMarkersLabelsShadowAndLightsShareOrigin() throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 466, height: 678))
        let parent = UIViewController(); window.rootViewController = parent; window.isHidden = false
        defer { window.isHidden = true }
        let map = WorldMapScrollView(frame: CGRect(x: 0, y: 0, width: 382, height: 678))
        parent.view.addSubview(map)
        map.updatePresentation(profile: .conventional, visible: true, visualViewport: window.bounds)
        map.updatePosition(WorldMapGeometryProfile.duoInitialCenter) { _ in }
        map.updateNightLights(southernCities)
        map.updateMarkers(southernCities, at: instant, timeFormatPreference: "twentyFourHour", localeIdentifier: "en_US")
        map.updateIllumination(at: instant); map.layoutIfNeeded()
        let overlay = try XCTUnwrap(map.dayNightOverlay)
        XCTAssertNotNil(overlay.renderer.lightPipeline)
        let originalTop = map.repeatedImage.frame.minY, originalSide = map.mapCanvas.bounds.width
        let originalOffset = map.contentOffset, center = map.normalizedCenter
        let originalMarkers = map.markers.map { $0.convert($0.indicatorBounds, to: map) }
        let originalLabels = map.markers.map { $0.convert($0.placedLabelBounds, to: map) }
        let originalSharedLabels = map.sharedLabels.map { $0.convert($0.labelBounds, to: map) }
        let originalLights = map.nightLights
        let originalShadowSpan = overlay.uniforms.viewport.w
        map.updatePresentation(profile: .duoOuter, visible: true, visualViewport: window.bounds)
        map.layoutIfNeeded()
        let geometry = WorldMapGeometryProfile.duoOuter.canvas(in: map.bounds.size)
        let delta = geometry.top - originalTop
        XCTAssertEqual(map.mapCanvas.bounds.width, originalSide)
        XCTAssertEqual(map.contentOffset, originalOffset)
        XCTAssertEqual(map.normalizedCenter, center)
        XCTAssertEqual(map.repeatedImage.frame, map.repeatedCanvas.frame)
        XCTAssertEqual(map.imageView.frame, map.mapCanvas.bounds)
        XCTAssertEqual(map.repeatedImage.frame.minY, geometry.top, accuracy: 1e-8)
        XCTAssertTrue(map.dayNightOverlay === overlay)
        XCTAssertEqual(overlay.uniforms.viewport.y, Float(-geometry.top / geometry.side), accuracy: 1e-7)
        XCTAssertEqual(overlay.uniforms.viewport.w, originalShadowSpan)
        XCTAssertEqual(map.nightLights, originalLights)
        XCTAssertGreaterThan(overlay.lightData.count, 0)
        XCTAssertEqual(map.sharedLabels.count, originalSharedLabels.count)
        for (index, label) in map.sharedLabels.enumerated() {
            XCTAssertEqual(label.convert(label.labelBounds, to: map).minY - originalSharedLabels[index].minY, delta, accuracy: 1e-6)
        }
        for (index, marker) in map.markers.enumerated() {
            let dot = marker.convert(marker.indicatorBounds, to: map)
            let label = marker.convert(marker.placedLabelBounds, to: map)
            XCTAssertEqual(dot.minX, originalMarkers[index].minX, accuracy: 1e-6)
            XCTAssertEqual(dot.midY - originalMarkers[index].midY, delta, accuracy: 1e-6)
            XCTAssertEqual(label.minY - originalLabels[index].minY, delta, accuracy: 1e-6)
            // The 32-point marker export includes shadow padding. Its geographic
            // dot anchor is local Y=6, rather than the export rectangle midpoint.
            let anchor = marker.convert(CGPoint(x: marker.bounds.midX, y: 6), to: map)
            XCTAssertEqual(anchor.y, geometry.top + marker.normalizedPoint.y * geometry.side, accuracy: 1e-6)
            XCTAssertGreaterThan(dot.midY, 0); XCTAssertLessThan(dot.midY, map.bounds.height)
            let city = southernCities[index]
            let light = try XCTUnwrap(map.nightLights.first { abs($0.coordinate.latitude - city.latitude!) < 1e-7 && abs($0.coordinate.longitude - city.longitude!) < 1e-7 })
            XCTAssertEqual(geometry.top + CGFloat(light.position.y) * geometry.side, anchor.y, accuracy: 0.0001)
        }
    }

    func testMapAndRendererSurviveRepeatedDuoProfilesAndVisibilityChanges() throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 466, height: 678))
        let parent = UIViewController(); window.rootViewController = parent; window.isHidden = false
        defer { window.isHidden = true }
        let map = WorldMapScrollView(frame: CGRect(x: 0, y: 0, width: 382, height: 678))
        parent.view.addSubview(map)
        map.updatePresentation(profile: .duoOuter, visible: true)
        map.updatePosition(0.314159) { _ in }
        map.updateIllumination(at: instant); map.updateNightLights(southernCities)
        map.updateMarkers(southernCities, at: instant, timeFormatPreference: "twentyFourHour", localeIdentifier: "en_US")
        map.layoutIfNeeded()
        let overlay = try XCTUnwrap(map.dayNightOverlay), renderer = overlay.renderer
        let markerIDs = map.markers.map(ObjectIdentifier.init)
        for i in 0..<20 {
            let profile: WorldMapGeometryProfile = i.isMultiple(of: 2) ? .duoInner : .duoOuter
            map.updatePresentation(profile: profile, visible: true)
            map.frame.size = i.isMultiple(of: 2) ? CGSize(width: 527, height: 669) : CGSize(width: 382, height: 678)
            map.layoutIfNeeded()
            XCTAssertTrue(map.dayNightOverlay === overlay); XCTAssertTrue(overlay.renderer === renderer)
            XCTAssertEqual(map.markers.map(ObjectIdentifier.init), markerIDs)
            XCTAssertEqual(map.normalizedCenter, 0.314159, accuracy: 1e-10)
            XCTAssertEqual(map.illuminationInstant, instant)
            XCTAssertEqual(map.contentOffset.y, 0)
            XCTAssertEqual(overlay.uniforms.viewport.y, Float(-map.repeatedImage.frame.minY / map.mapCanvas.bounds.width), accuracy: 1e-7)
            map.updatePresentation(profile: profile, visible: false)
            XCTAssertTrue(overlay.isHidden)
            map.updatePresentation(profile: profile, visible: true); map.layoutIfNeeded()
            XCTAssertFalse(overlay.isHidden); XCTAssertFalse(overlay.isSuspended)
        }
    }

    func testConventionalAndInnerGeometryRetainOriginalArithmetic() {
        for size in [CGSize(width: 375, height: 667), CGSize(width: 402, height: 874), CGSize(width: 440, height: 956)] {
            let scale = max(size.width / 393, size.height / 852)
            let geometry = WorldMapGeometryProfile.conventional.canvas(in: size)
            XCTAssertEqual(geometry.side, 1129 * scale); XCTAssertEqual(geometry.top, -13 * scale)
        }
        for size in [CGSize(width: 527, height: 669), CGSize(width: 1054, height: 1338)] {
            let scale = max(size.width / 527, size.height / 669)
            let geometry = WorldMapGeometryProfile.duoInner.canvas(in: size)
            XCTAssertEqual(geometry.side, 1022 * scale); XCTAssertEqual(geometry.top, -97 * scale)
        }
    }
}
