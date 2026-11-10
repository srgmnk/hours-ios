import XCTest
import UIKit
import CoreText
@testable import MapHarness

@MainActor final class MapLabelAnchorTests: XCTestCase {
    private let cities = [
        City(name: "London", timeZoneID: "Europe/London", canonicalID: "London", latitude: 51.5074, longitude: -0.1278),
        City(name: "Madrid", timeZoneID: "Europe/Madrid", canonicalID: "Madrid", latitude: 40.4168, longitude: -3.7038),
        City(name: "Moscow", timeZoneID: "Europe/Moscow", canonicalID: "Moscow", latitude: 55.7558, longitude: 37.6173),
        City(name: "Casablanca", timeZoneID: "Africa/Casablanca", canonicalID: "Casablanca", latitude: 33.5731, longitude: -7.5898)
    ]

    private func outlinedGlyphBounds(_ label: WorldMapMarkerLabel) -> CGRect {
        let text = label.attributedText!
        let font = text.attribute(.font, at: 0, effectiveRange: nil) as! UIFont
        let ink = CTLineGetBoundsWithOptions(CTLineCreateWithAttributedString(text), .useGlyphPathBounds)
        return CGRect(x: label.frame.midX - label.textSize.width / 2 + ink.minX,
                      y: label.frame.midY - label.textSize.height / 2 + font.ascender - ink.maxY,
                      width: ink.width, height: ink.height)
            .insetBy(dx: -1 / WorldMapMarkerView.labelScale, dy: -1 / WorldMapMarkerView.labelScale)
    }

    func testMeasuredFourCityGapsAndDefaultPlacement() throws {
        let key = AppTimeFormatPreference.storageKey
        let saved = UserDefaults.standard.object(forKey: key)
        defer { UserDefaults.standard.set(saved, forKey: key) }
        let date = ISO8601DateFormatter().date(from: "2026-11-09T16:37:00Z")!
        for format in ["twentyFourHour", "twelveHour"] {
            UserDefaults.standard.set(format, forKey: key)
            let map = WorldMapScrollView(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
            map.updateMarkers(cities, at: date, timeFormatPreference: format, localeIdentifier: "en_US")
            map.layoutIfNeeded()
            let expected = [9.681, format == "twelveHour" ? 12.747 : 5.648, 5.986, 5.942]
            for (index, marker) in map.markers.enumerated() {
                let ink = marker.convert(outlinedGlyphBounds(marker.nameLabel).union(outlinedGlyphBounds(marker.timeLabel)), to: map.mapCanvas)
                let dot = map.hitDots[index].bounds
                let dx = max(0, max(ink.minX - dot.midX, dot.midX - ink.maxX))
                let dy = max(0, max(ink.minY - dot.midY, dot.midY - ink.maxY))
                let distance = hypot(dx, dy) - dot.width / 2
                XCTAssertEqual(distance, expected[index], accuracy: 0.02, marker.cityID)
                XCTAssertGreaterThan(distance, 0, "Visible label must clear its own pin")
                // Collision bounds retain the full measured text effects.
                XCTAssertEqual(map.hitLabels[index].bounds, marker.convert(marker.placedLabelBounds, to: map.mapCanvas))
            }
            XCTAssertEqual(map.placementOffsets[2], .zero, "Moscow keeps default below")
            XCTAssertEqual(map.placementOffsets[3], .zero, "Casablanca keeps default below")
        }
    }

    func testAnchorInsetIsFourRenderedPointsRegardlessOfScale() {
        // A blocker at the default position forces the other label above. These
        // rectangles are already screen-point geometry, as in the live map.
        let label = CGRect(x: 70, y: 110, width: 60, height: 48)
        let dot = CGRect(x: 94, y: 94, width: 12, height: 12)
        let blocker = CGRect(x: 50, y: 115, width: 100, height: 80)
        let items = [WorldMapLabelPlacement.Item(cityIDs: ["target"], members: [0], labelBounds: label, dotBounds: dot),
                     WorldMapLabelPlacement.Item(cityIDs: ["blocker"], members: [1], labelBounds: blocker,
                                                 dotBounds: CGRect(x: 94, y: 195, width: 12, height: 12))]
        for scale: CGFloat in [0.75, WorldMapMarkerView.labelScale, 1, 1.25] {
            let offsets = WorldMapLabelPlacement.offsets(for: items, dots: items.map(\.dotBounds), scale: scale)
            XCTAssertEqual(offsets[0].x, 0, accuracy: 1e-6)
            XCTAssertEqual(offsets[0].y, dot.minY - 4 * scale - (label.maxY - 4), accuracy: 1e-6)
            XCTAssertEqual(WorldMapLabelPlacement.offsets(for: [items[0]], dots: [dot], scale: scale), [.zero])
        }
    }

    func testMeridiemTransitionsOwnPinClearanceAndWrapAcrossProfiles() {
        let key = AppTimeFormatPreference.storageKey
        let saved = UserDefaults.standard.object(forKey: key)
        UserDefaults.standard.set("twelveHour", forKey: key)
        defer { UserDefaults.standard.set(saved, forKey: key) }
        let profiles: [(WorldMapGeometryProfile, CGSize)] = [
            (.conventional, CGSize(width: 393, height: 852)), (.duoOuter, CGSize(width: 382, height: 678)),
            (.duoInner, CGSize(width: 527, height: 669)), (.duoInner, CGSize(width: 455.667, height: 669)),
            (.duoInnerPortrait, CGSize(width: 669, height: 476)), (.duoInnerPortrait, CGSize(width: 669, height: 407)),
            (.duoOuter, CGSize(width: 375, height: 669))
        ]
        let formatter = ISO8601DateFormatter()
        for (profile, size) in profiles {
            for style in [UIUserInterfaceStyle.light, .dark] {
                let map = WorldMapScrollView(frame: CGRect(origin: .zero, size: size))
                map.overrideUserInterfaceStyle = style
                map.updatePresentation(profile: profile, visible: true)
                var anchors: [CGRect] = []
                for time in ["11:59", "12:00", "23:59", "00:00"] {
                    let date = formatter.date(from: "2026-11-09T\(time):00Z")!
                    map.updateMarkers(cities, at: date, timeFormatPreference: "twelveHour", localeIdentifier: "en_US", primaryCityID: "Madrid")
                    map.layoutIfNeeded()
                    if anchors.isEmpty { anchors = map.hitDots.map(\.bounds) }
                    for (dot, anchor) in zip(map.hitDots.map(\.bounds), anchors) {
                        XCTAssertEqual(dot.midX, anchor.midX, accuracy: 1e-6)
                        XCTAssertEqual(dot.midY, anchor.midY, accuracy: 1e-6)
                        XCTAssertEqual(dot.width, anchor.width, accuracy: 1e-6)
                        XCTAssertEqual(dot.height, anchor.height, accuracy: 1e-6)
                    }
                    for (i, marker) in map.markers.enumerated() where !marker.labelsHidden {
                        let ink = marker.convert(outlinedGlyphBounds(marker.nameLabel).union(outlinedGlyphBounds(marker.timeLabel)), to: map.mapCanvas)
                        let dot = map.hitDots[i].bounds
                        let dx = max(0, max(ink.minX - dot.midX, dot.midX - ink.maxX))
                        let dy = max(0, max(ink.minY - dot.midY, dot.midY - ink.maxY))
                        XCTAssertGreaterThan(hypot(dx, dy), dot.width / 2)
                    }
                    let offsets = map.placementOffsets
                    let items = map.lastPlacementItems
                    map.contentOffset.x += map.mapCanvas.bounds.width
                    map.scrollViewDidScroll(map); map.layoutIfNeeded()
                    XCTAssertEqual(map.placementOffsets, offsets)
                    map.updateMarkers(cities, at: date, timeFormatPreference: "twelveHour", localeIdentifier: "en_US", primaryCityID: "Madrid")
                    XCTAssertEqual(map.lastPlacementItems, items)
                    XCTAssertEqual(map.placementOffsets, offsets)
                }
            }
        }
    }
}
