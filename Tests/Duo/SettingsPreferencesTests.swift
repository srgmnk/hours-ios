import XCTest
import SwiftUI
@testable import MapHarness

@MainActor final class SettingsPreferencesTests: XCTestCase {
    private let keys = [CityViewPreference.storageKey, AppAppearancePreference.storageKey,
                        AppTimeFormatPreference.storageKey]
    private var saved: [Any?] = []

    override func setUp() {
        super.setUp()
        saved = keys.map { UserDefaults.standard.object(forKey: $0) }
    }

    override func tearDown() {
        for (key, value) in zip(keys, saved) {
            if let value { UserDefaults.standard.set(value, forKey: key) }
            else { UserDefaults.standard.removeObject(forKey: key) }
        }
        super.tearDown()
    }

    func testExistingPreferencesSurviveSettingsRecreation() {
        XCTAssertEqual(CityViewPreference.allCases, [.basic, .compact])
        XCTAssertNil(CityViewPreference(rawValue: "cards"))
        for city in CityViewPreference.allCases {
            for appearance in AppAppearancePreference.allCases {
                for time in AppTimeFormatPreference.allCases {
                    let settings = SettingsSheetView()
                    settings.cityViewPreferenceRawValue = city.rawValue
                    settings.appearancePreferenceRawValue = appearance.rawValue
                    settings.timeFormatPreferenceRawValue = time.rawValue
                    let reopened = SettingsSheetView()
                    XCTAssertEqual(reopened.selectedCityViewPreference, city)
                    XCTAssertEqual(reopened.selectedAppearancePreference, appearance)
                    XCTAssertEqual(reopened.selectedTimeFormatPreference, time)
                    XCTAssertEqual(UserDefaults.standard.string(forKey: keys[0]), city.rawValue)
                    XCTAssertEqual(UserDefaults.standard.string(forKey: keys[1]), appearance.rawValue)
                    XCTAssertEqual(UserDefaults.standard.string(forKey: keys[2]), time.rawValue)
                }
            }
        }
    }

    func testTimeChoicesUseExistingFormatterAndKeepLegacySystemValue() {
        let settings = SettingsSheetView()
        let instant = Date(timeIntervalSince1970: 1735736400) // 13:00 UTC
        let zone = TimeZone(secondsFromGMT: 0)!
        settings.timeFormatPreferenceRawValue = AppTimeFormatPreference.twentyFourHour.rawValue
        let twentyFour = CityTimeFormatter.formatTimeComponents(instant, in: zone)
        XCTAssertEqual(twentyFour.numeric, "13:00")
        XCTAssertNil(twentyFour.meridiem)
        settings.timeFormatPreferenceRawValue = AppTimeFormatPreference.twelveHour.rawValue
        let twelve = CityTimeFormatter.formatTimeComponents(instant, in: zone)
        XCTAssertEqual(twelve.numeric, "01:00")
        XCTAssertNotNil(twelve.meridiem)
        settings.timeFormatPreferenceRawValue = AppTimeFormatPreference.system.rawValue
        let expected: AppTimeFormatPreference = CityTimeFormatter.formatTimeComponents(instant, in: zone).meridiem == nil ? .twentyFourHour : .twelveHour
        XCTAssertEqual(settings.displayedTimeFormatPreference, expected)
        XCTAssertEqual(settings.timeFormatPreferenceRawValue, "system")
    }

    func testFigmaGeometryAndCaptureSelectionMatrix() throws {
        for city in CityViewPreference.allCases {
            for appearance in AppAppearancePreference.allCases {
                for time in [AppTimeFormatPreference.twentyFourHour, .twelveHour] {
                    let settings = SettingsSheetView()
                    settings.cityViewPreferenceRawValue = city.rawValue
                    settings.appearancePreferenceRawValue = appearance.rawValue
                    settings.timeFormatPreferenceRawValue = time.rawValue
                    let theme = AppTheme.light
                    let renderer = ImageRenderer(content: settings.settingsBlock
                        .environment(\.appTheme, theme)
                        .environment(\.dynamicTypeSize, .large)
                        .frame(width: 377)
                        .background(theme.screenBackground))
                    renderer.scale = 3
                    let image = try XCTUnwrap(renderer.uiImage)
                    XCTAssertEqual(image.size.width, 377, accuracy: 0.01)
                    XCTAssertEqual(image.size.height, 298, accuracy: 0.01)
                    let attachment = XCTAttachment(image: image)
                    attachment.name = "preferences-light-\(city.rawValue)-\(appearance.rawValue)-\(time.rawValue)"
                    attachment.lifetime = .keepAlways
                    add(attachment)
                }
            }
        }
    }

    func testDynamicTypeAndAdaptiveWidthsGrowWithoutHorizontalOverflow() throws {
        let settings = SettingsSheetView()
        for width: CGFloat in [304, 359, 377, 450, 636] {
            for size in [DynamicTypeSize.large, .xxxLarge, .accessibility5] {
                let renderer = ImageRenderer(content: settings.settingsBlock
                    .environment(\.dynamicTypeSize, size)
                    .frame(width: width))
                let image = try XCTUnwrap(renderer.uiImage)
                XCTAssertEqual(image.size.width, width, accuracy: 0.01)
                XCTAssertGreaterThanOrEqual(image.size.height, 298)
                if size == .accessibility5 {
                    XCTAssertGreaterThan(image.size.height, 298)
                    let attachment = XCTAttachment(image: image)
                    attachment.name = "preferences-accessibility5-\(Int(width))"
                    attachment.lifetime = .keepAlways
                    add(attachment)
                }
            }
        }
    }
}
