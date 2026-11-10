import XCTest
import UIKit
import CoreText
@testable import MapHarness

@MainActor final class MapTimeDigitTests: XCTestCase {
    private let times = ["11:11", "12:22", "08:59", "09:00", "19:59", "20:00", "23:59", "00:00"]

    // The exact proportional rounded font used before adding the number feature.
    private func proportionalTime(_ text: String) -> NSAttributedString {
        let size = 18 / WorldMapMarkerView.labelScale
        let font = UIFont.systemFont(ofSize: size, weight: .bold)
        return NSAttributedString(string: text, attributes: [
            .font: UIFont(descriptor: font.fontDescriptor.withDesign(.rounded)!, size: size),
            .kern: -0.04 * size, .foregroundColor: UIColor.white
        ])
    }

    func testTabularAdvancesAndWidthsPreserveProportionalOtherGlyphs() throws {
        let scale = WorldMapMarkerView.labelScale
        let width = WorldMapMarkerView.label("0", size: 18).size().width
        for digit in "0123456789" {
            XCTAssertEqual(WorldMapMarkerView.label(String(digit), size: 18).size().width, width, accuracy: 1e-6)
        }
        let reference = CTLineCreateWithAttributedString(WorldMapMarkerView.label(times[0], size: 18))
        for time in times {
            let text = WorldMapMarkerView.label(time, size: 18)
            let line = CTLineCreateWithAttributedString(text)
            for index in 0...time.utf16.count {
                XCTAssertEqual(CTLineGetOffsetForStringIndex(line, index, nil),
                               CTLineGetOffsetForStringIndex(reference, index, nil), accuracy: 1e-6, time)
            }
            print("MAP_TIME_WIDTH \(time) before_pt=\(proportionalTime(time).size().width * scale) after_pt=\(text.size().width * scale)")
        }
        for text in [":", " ", "AM", "PM", "W", "i"] {
            XCTAssertEqual(WorldMapMarkerView.label(text, size: 18).size().width,
                           proportionalTime(text).size().width, accuracy: 1e-6, text)
        }
        XCTAssertNotEqual(WorldMapMarkerView.label("W", size: 18).size().width,
                          WorldMapMarkerView.label("i", size: 18).size().width)
        let name = WorldMapMarkerView.label("City 1111", size: 14)
        let nameFont = try XCTUnwrap(name.attribute(.font, at: 0, effectiveRange: nil) as? UIFont)
        XCTAssertNil(nameFont.fontDescriptor.object(forKey: .featureSettings))
        XCTAssertNotEqual(name.size().width, WorldMapMarkerView.label("City 2222", size: 14).size().width)
    }

    func testTimeUpdatesKeepCachedInkPlacementAndPinsStableAcrossThemesAndProfiles() throws {
        let key = AppTimeFormatPreference.storageKey
        let saved = UserDefaults.standard.object(forKey: key)
        UserDefaults.standard.set(AppTimeFormatPreference.twentyFourHour.rawValue, forKey: key)
        defer {
            if let saved { UserDefaults.standard.set(saved, forKey: key) }
            else { UserDefaults.standard.removeObject(forKey: key) }
        }
        let cities = [("Group one", 28.61, 77.2), ("Group two", 28.62, 77.3), ("Solo", 13.75, 100.5)].map {
            City(name: $0.0, timeZoneID: "Etc/UTC", canonicalID: "digits-\($0.0)", latitude: $0.1, longitude: $0.2)
        }
        let profiles: [(WorldMapGeometryProfile, CGSize)] = [
            (.conventional, CGSize(width: 393, height: 852)), (.duoOuter, CGSize(width: 382, height: 678)),
            (.duoInner, CGSize(width: 527, height: 669)), (.duoInner, CGSize(width: 455.667, height: 669)),
            (.duoInnerPortrait, CGSize(width: 669, height: 476)), (.duoInnerPortrait, CGSize(width: 669, height: 407)),
            (.duoOuter, CGSize(width: 375, height: 669))
        ]
        let formatter = ISO8601DateFormatter()
        for (profile, size) in profiles {
            for style in [UIUserInterfaceStyle.light, .dark] {
                for primary in [cities[1].id, cities[2].id] {
                    let map = WorldMapScrollView(frame: CGRect(origin: .zero, size: size))
                    map.overrideUserInterfaceStyle = style
                    map.updatePresentation(profile: profile, visible: true)
                    var dots: [CGRect] = [], labels: [CGRect] = [], groups: [[City.ID]] = []
                    for time in times {
                        let date = try XCTUnwrap(formatter.date(from: "2026-11-09T\(time):00Z"))
                        map.updateMarkers(cities, at: date, timeFormatPreference: "twentyFourHour", localeIdentifier: "en_US", primaryCityID: primary)
                        map.layoutIfNeeded()
                        if dots.isEmpty {
                            dots = map.hitDots.map(\.bounds); labels = map.hitLabels.map(\.bounds)
                            groups = map.sharedLabels.map(\.cityIDs)
                            XCTAssertEqual(groups, [[cities[0].id, cities[1].id]])
                        }
                        XCTAssertEqual(map.hitDots.map(\.bounds), dots)
                        XCTAssertEqual(map.hitLabels.map(\.bounds), labels)
                        XCTAssertEqual(map.sharedLabels.map(\.cityIDs), groups)
                        for marker in map.markers {
                            XCTAssertEqual(marker.displayedTime, time)
                            let text = try XCTUnwrap(marker.timeLabel.attributedText)
                            XCTAssertEqual(marker.timeLabel.textSize, text.size())
                            XCTAssertEqual(marker.timeLabel.outlineText?.string, time)
                            XCTAssertEqual(marker.timeLabel.frame.midX, marker.nameLabel.frame.midX, accuracy: 1e-6)
                            XCTAssertFalse(marker.updateTime(at: date))
                            XCTAssertTrue(marker.timeLabel.attributedText === text, "Unchanged time retains cached layout")
                        }
                        for group in map.sharedLabels {
                            let text = try XCTUnwrap(group.timeLabel.attributedText)
                            XCTAssertEqual(text.string, time)
                            XCTAssertEqual(group.timeLabel.textSize, text.size())
                            XCTAssertEqual(group.timeLabel.outlineText?.string, time)
                            XCTAssertEqual(group.timeLabel.frame.midX, group.nameLabel.frame.midX, accuracy: 1e-6)
                        }
                        for i in map.hitLabels.indices {
                            for j in map.hitLabels.indices where j > i {
                                let a = map.hitLabels[i].bounds
                                let b = WorldMapPeriodic.nearest(map.hitLabels[j].bounds, to: a.midX, period: map.mapCanvas.bounds.width)
                                XCTAssertFalse(a.intersects(b))
                            }
                        }
                    }
                }
            }
        }
    }
}
