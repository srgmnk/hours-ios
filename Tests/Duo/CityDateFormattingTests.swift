import XCTest
import SwiftUI
import Combine
@testable import MapHarness

@MainActor final class CityDateFormattingTests: XCTestCase {
    private let localeIDs = ["en_US", "en_GB", "ru_RU", "de_DE", "fr_FR", "ja_JP", "zh_CN", "ar_SA"]
    private func instant(_ value: String) -> Date { ISO8601DateFormatter().date(from: value)! }
    private let tokyo = TimeZone(identifier: "Asia/Tokyo")!
    private let losAngeles = TimeZone(identifier: "America/Los_Angeles")!

    func testRegionalOrderingSymbolsAndPunctuation() {
        let date = instant("2026-11-09T12:00:00Z")
        let expected = ["Mon, Nov 9", "Mon 9 Nov", "Пн, 9 нояб.", "Mo. 9. Nov.",
                        "lun. 9 nov.", "11月9日(月)", "11月9日 周一", "اثنين، ٢٩ جمادى الأولى"]
        // Repeat in reverse to catch stale locale/calendar state in the shared formatter.
        for index in Array(localeIDs.indices) + localeIDs.indices.reversed() {
            let result = CityTimeFormatter.formatDate(date, in: tokyo, locale: Locale(identifier: localeIDs[index]))
            XCTAssertEqual(result, expected[index], localeIDs[index])
            print("CITY_DATE_EXAMPLE \(localeIDs[index]): \(result)")
        }
    }

    func testDeviceLanguageKeepsIndependentRegionCalendarAndNumberPreferences() {
        let date = instant("2026-11-09T12:00:00Z")
        for (region, language, expected) in [
            ("en_US", "en-GB", "Mon, Nov 9"),
            ("en_GB", "en-US", "Mon 9 Nov"),
            ("en_RU", "ru", "Пн, 9 нояб."),
            ("en_SA", "ar", "اثنين، ٢٩ جمادى الأولى"),
            ("en_SA@calendar=gregorian;numbers=latn", "ar", "اثنين، 9 نوفمبر")
        ] {
            let regional = Locale(identifier: region)
            let resolved = CityTimeFormatter.deviceDateLocale(regionLocale: regional, preferredLocale: Locale(identifier: language))
            XCTAssertEqual(resolved.region, regional.region)
            XCTAssertEqual(resolved.calendar.identifier, regional.calendar.identifier)
            XCTAssertEqual(CityTimeFormatter.formatDate(date, in: tokyo, locale: resolved), expected)
        }
        let regional = Locale(identifier: "fr_FR")
        XCTAssertEqual(CityTimeFormatter.deviceDateLocale(regionLocale: regional, preferredLocale: nil), regional)
    }

    func testDefaultUsesPreferredDeviceLocaleDespiteEnglishAppFallback() {
        let date = instant("2026-11-09T12:00:00Z")
        let preferred = CityTimeFormatter.deviceDateLocale()
        let expected = CityTimeFormatter.formatDate(date, in: tokyo, locale: preferred)
        XCTAssertEqual(CityTimeFormatter.formatDate(date, in: tokyo), expected)
        if preferred.language.languageCode != Locale.current.language.languageCode {
            XCTAssertNotEqual(expected, CityTimeFormatter.formatDate(date, in: tokyo, locale: .current))
        }
        // Date localization does not change the existing time preference or locale.
        let before = CityTimeFormatter.formatTime(date, in: tokyo)
        _ = CityTimeFormatter.formatDate(date, in: tokyo, locale: Locale(identifier: "ar_SA"))
        XCTAssertEqual(CityTimeFormatter.formatTime(date, in: tokyo), before)
    }

    func testCityMidnightIsIndependentOfDeviceTimeZoneAndLocale() {
        let saved = NSTimeZone.default
        defer { NSTimeZone.default = saved }
        let before = instant("2026-11-09T14:59:00Z")
        let after = instant("2026-11-09T15:00:00Z")
        for deviceZone in [losAngeles, TimeZone(identifier: "Pacific/Kiritimati")!] {
            NSTimeZone.default = deviceZone
            for id in localeIDs {
                let locale = Locale(identifier: id)
                let tokyoBefore = CityTimeFormatter.formatDate(before, in: tokyo, locale: locale)
                let tokyoAfter = CityTimeFormatter.formatDate(after, in: tokyo, locale: locale)
                XCTAssertNotEqual(tokyoBefore, tokyoAfter, id)
                XCTAssertEqual(CityTimeFormatter.formatDate(before, in: losAngeles, locale: locale), tokyoBefore, id)
                XCTAssertEqual(CityTimeFormatter.formatDate(after, in: losAngeles, locale: locale), tokyoBefore, id)
            }
        }
        XCTAssertEqual(CityTimeFormatter.formatDate(after, in: tokyo, locale: Locale(identifier: "en_US")), "Tue, Nov 10")
        XCTAssertEqual(CityTimeFormatter.formatDate(after, in: losAngeles, locale: Locale(identifier: "en_US")), "Mon, Nov 9")
    }

    func testCalendarPreferenceAndDSTTransitions() {
        let date = instant("2026-11-09T12:00:00Z")
        let gregorianArabic = Locale(identifier: "ar_SA@calendar=gregorian")
        XCTAssertEqual(CityTimeFormatter.formatDate(date, in: tokyo, locale: gregorianArabic), "اثنين، ٩ نوفمبر")
        let zone = TimeZone(identifier: "America/New_York")!
        for (before, after, expected) in [
            ("2026-03-08T06:59:00Z", "2026-03-08T07:00:00Z", "Sun, Mar 8"),
            ("2026-11-01T05:59:00Z", "2026-11-01T06:00:00Z", "Sun, Nov 1")
        ] {
            let a = instant(before), b = instant(after)
            XCTAssertNotEqual(zone.secondsFromGMT(for: a), zone.secondsFromGMT(for: b))
            for date in [a, b] {
                XCTAssertEqual(CityTimeFormatter.formatDate(date, in: zone, locale: Locale(identifier: "en_US")), expected)
            }
        }
    }

    func testWheelCrossesMidnightAndAllModesUseTheSameDate() {
        let model = TimeDialViewModel()
        model.tickerTask?.cancel()
        model.now = instant("2026-11-09T14:55:00Z")
        model.beginDialDrag()
        let city = City(name: "Tokyo", timeZoneID: tokyo.identifier, canonicalID: "date-tokyo")
        let previous = CityTimeFormatter.formatDate(model.selectedInstant, in: tokyo)
        model.updateDialRotation(-1.25) // one five-minute tick
        XCTAssertEqual(model.selectedInstant, instant("2026-11-09T15:00:00Z"))
        let expected = CityTimeFormatter.formatDate(model.selectedInstant, in: tokyo)
        XCTAssertNotEqual(previous, expected)
        for style in CityViewPreference.allCases {
            let card = CityCardView(city: city, selectedInstant: model.selectedInstant, referenceTimeZone: losAngeles,
                                    isCurrent: false, cityViewPreference: style, cardBackgroundColor: .white)
            XCTAssertEqual(card.dateText, expected)
            XCTAssertTrue(card.accessibilitySummary.contains(expected))
        }
    }

    func testExistingRefreshPublishesAfterInactiveGapAndForUnchangedWheelInstant() {
        let model = TimeDialViewModel()
        model.tickerTask?.cancel()
        model.now = instant("2026-11-09T14:59:00Z")
        let before = CityTimeFormatter.formatDate(model.selectedInstant, in: tokyo)
        // The existing ticker resumes with the current time after an inactive gap.
        model.now = instant("2026-11-09T15:01:00Z")
        XCTAssertNotEqual(CityTimeFormatter.formatDate(model.selectedInstant, in: tokyo), before)
        model.beginDialDrag()
        model.updateDialRotation(-1.25)
        let selected = model.selectedInstant
        var published = [Date]()
        let observation = model.$selectedInstant.sink { published.append($0) }
        model.now = instant("2026-11-09T16:01:00Z")
        XCTAssertEqual(model.selectedInstant, selected)
        // A refresh still reaches card formatting when a locale changes while
        // the wheel is holding a selected instant; no extra timer is needed.
        XCTAssertEqual(published, [selected, selected])
        withExtendedLifetime(observation) {}
    }

    func testRetainedListRefreshesDatesAndModeChanges() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        let controller = CityListReorderViewController()
        window.rootViewController = controller; window.makeKeyAndVisible()
        defer { window.isHidden = true; previous?.makeKeyAndVisible() }
        let collection = controller.collectionView
        let cities = [City(name: "Tokyo", timeZoneID: tokyo.identifier, canonicalID: "date-tokyo"),
                      City(name: "Los Angeles", timeZoneID: losAngeles.identifier, canonicalID: "date-la")]
        let before = instant("2026-11-09T14:59:00Z"), after = instant("2026-11-09T15:00:00Z")
        for style in [CityViewPreference.basic, .compact, .cards, .basic, .cards] {
            for date in [before, after] {
                controller.apply(cities: cities, selectedInstant: date, userCurrentLocationItem: nil,
                                 cityViewPreference: style, topInset: 25, bottomInset: 34, cardBackgroundColor: .white)
                controller.view.layoutIfNeeded()
                try await Task.sleep(for: .milliseconds(100))
                XCTAssertTrue(controller.collectionView === collection)
                XCTAssertEqual(controller.selectedInstant, date)
                XCTAssertEqual(controller.citiesLocal, cities)
                for (index, city) in cities.enumerated() {
                    let cell = try XCTUnwrap(collection.cellForItem(at: IndexPath(item: index, section: 0)))
                    XCTAssertEqual(cell.frame.height, style == .cards ? 200 : (style == .basic ? 140 : 88), accuracy: 0.5)
                    if style == .cards {
                        XCTAssertTrue(cell.accessibilityLabel?.contains(CityTimeFormatter.formatDate(date, in: city.timeZone)) == true)
                    }
                }
            }
        }
    }

    // Run with xcodebuild -testLanguage/-testRegion to exercise the real device
    // locale default through production cards, including narrow Duo grid cells.
    func testDeviceLocaleLayoutCaptures() throws {
        let deviceLocale = CityTimeFormatter.deviceDateLocale()
        let yearStart = instant("2026-01-01T12:00:00Z")
        let widest = (0..<365).map { yearStart.addingTimeInterval(Double($0) * 86400) }.max {
            func width(_ date: Date) -> CGFloat {
                (CityTimeFormatter.formatDate(date, in: tokyo) as NSString).size(withAttributes: [
                    .font: UIFont.systemFont(ofSize: 14, weight: .medium), .kern: -0.42
                ]).width
            }
            return width($0) < width($1)
        }!
        for date in [instant("2026-09-23T12:00:00Z"), instant("2026-11-09T12:00:00Z"), widest] {
            let value = ISO8601DateFormatter().string(from: date)
            let city = City(name: "Tokyo", timeZoneID: tokyo.identifier, canonicalID: "date-tokyo")
            print("CITY_DATE_DEVICE_LOCALE \(deviceLocale.identifier) (app \(Locale.current.identifier)): \(CityTimeFormatter.formatDate(date, in: tokyo))")
            func card(_ style: CityViewPreference, _ width: CGFloat) -> some View {
                CityCardView(city: city, selectedInstant: date, referenceTimeZone: tokyo, isCurrent: true,
                             cityViewPreference: style, cardBackgroundColor: .white)
                    .frame(width: width)
            }
            let content = VStack(spacing: 12) {
                Text(deviceLocale.identifier).font(.headline)
                card(.basic, 300)
                card(.compact, 300)
                HStack(spacing: 8) { card(.cards, 142); card(.cards, 180) }
            }
            .padding(12)
            .environment(\.appTheme, .light)
            .environment(\.layoutDirection, Locale.characterDirection(forLanguage: deviceLocale.language.languageCode?.identifier ?? "en") == .rightToLeft ? .rightToLeft : .leftToRight)
            .background(Color.gray.opacity(0.2))
            let renderer = ImageRenderer(content: content)
            renderer.scale = 2
            let image = try XCTUnwrap(renderer.uiImage)
            let attachment = XCTAttachment(image: image)
            attachment.name = "city-dates-\(deviceLocale.identifier)-\(value.prefix(10))"
            attachment.lifetime = .keepAlways; add(attachment)
        }
    }
}
