import XCTest
import CoreLocation
import SwiftUI
import Vision
@testable import MapHarness

// The isolated Duo harness exposes private production members in disposable
// copies. Seed known coordinates so these tests never perform a MapKit request.
extension CitySunEventProvider {
    func seedSolarTestCoordinate(_ coordinate: CLLocationCoordinate2D, id: String) {
        coordinateCache[id] = coordinate
    }
}

@MainActor final class SunEventDSTTests: XCTestCase {
    private struct Place {
        let zone: TimeZone
        let coordinate: CLLocationCoordinate2D
        init(_ id: String, _ latitude: Double, _ longitude: Double) {
            zone = TimeZone(identifier: id)!
            coordinate = .init(latitude: latitude, longitude: longitude)
        }
        var calendar: Calendar {
            var result = Calendar(identifier: .gregorian)
            result.timeZone = zone
            return result
        }
        func noon(_ year: Int, _ month: Int, _ day: Int) -> Date {
            calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
        }
    }

    private let places = [
        Place("Europe/London", 51.5074, -0.1278),
        Place("America/New_York", 40.7128, -74.006),
        Place("Europe/Berlin", 52.52, 13.405),
        Place("Australia/Sydney", -33.8688, 151.2093),
        Place("Asia/Bangkok", 13.7563, 100.5018),
        Place("Asia/Tokyo", 35.6762, 139.6503),
        Place("Asia/Kolkata", 22.5726, 88.3639),
        Place("Asia/Kathmandu", 27.7172, 85.324),
        Place("Australia/Lord_Howe", -31.55, 159.0833),
        Place("Pacific/Chatham", -43.95, -176.55),
        Place("Pacific/Kiritimati", 1.8721, -157.4278),
        Place("Europe/Oslo", 69.6492, 18.9553),
        Place("Atlantic/Reykjavik", 64.1466, -21.9426)
    ]

    private func instant(_ text: String) -> Date { ISO8601DateFormatter().date(from: text)! }

    private func events(_ provider: CitySunEventProvider, _ place: Place, _ date: Date) async throws -> CitySunEventProvider.SunEvents {
        let result = await provider.sunEvents(for: date, coordinate: place.coordinate,
                                              timeZone: place.zone, calendar: place.calendar)
        return try XCTUnwrap(result, "\(place.zone.identifier) \(date)")
    }

    func testIndependentUSNOReferencesOnTransitionDays() async throws {
        // Retrieved 2026-11-10 from https://aa.usno.navy.mil/api/rstt/oneday
        // ?date=YYYY-MM-DD&coords=latitude,longitude&tz=0 (UTC, no DST).
        // Sydney sunrise uses the preceding UTC date. These are independently
        // calculated, minute-rounded references, not outputs from Hours' formula.
        // Allow 3 minutes for the existing non-iterative astronomical approximation.
        let fixtures: [(Int, Int, Int, String, String)] = [
            (0, 3, 29, "2026-03-29T05:43:00Z", "2026-03-29T18:29:00Z"),
            (0, 10, 25, "2026-10-25T06:42:00Z", "2026-10-25T16:47:00Z"),
            (1, 3, 8, "2026-03-08T11:19:00Z", "2026-03-08T22:55:00Z"),
            (1, 11, 1, "2026-11-01T11:26:00Z", "2026-11-01T21:52:00Z"),
            (2, 3, 29, "2026-03-29T04:48:00Z", "2026-03-29T17:35:00Z"),
            (2, 10, 25, "2026-10-25T05:50:00Z", "2026-10-25T15:50:00Z"),
            (3, 4, 5, "2026-04-04T20:10:00Z", "2026-04-05T07:45:00Z"),
            (3, 10, 4, "2026-10-03T19:29:00Z", "2026-10-04T08:00:00Z")
        ]
        let provider = CitySunEventProvider()
        for (index, month, day, sunrise, sunset) in fixtures {
            let place = places[index]
            let result = try await events(provider, place, place.noon(2026, month, day))
            XCTAssertEqual(result.sunrise.timeIntervalSince1970, instant(sunrise).timeIntervalSince1970, accuracy: 180, sunrise)
            XCTAssertEqual(result.sunset.timeIntervalSince1970, instant(sunset).timeIntervalSince1970, accuracy: 180, sunset)
        }
    }

    func testFoundationTransitionsBeforeDuringAfterAndAroundMidnight() async throws {
        let provider = CitySunEventProvider()
        // Discover dates from installed IANA rules, including half-hour DST and
        // quarter-hour offsets; do not assume a particular Sunday or hemisphere.
        for index in [0, 1, 2, 3, 8, 9] {
            let place = places[index]
            for year in [2016, 2026, 2036] {
                var cursor = place.noon(year, 1, 1)
                let end = place.noon(year + 1, 1, 1)
                var count = 0
                while let transition = place.zone.nextDaylightSavingTimeTransition(after: cursor), transition < end {
                    count += 1
                    XCTAssertNotEqual(place.zone.secondsFromGMT(for: transition.addingTimeInterval(-1)),
                                      place.zone.secondsFromGMT(for: transition.addingTimeInterval(1)))
                    var selections = [transition.addingTimeInterval(-1), transition.addingTimeInterval(1)]
                    for dayOffset in -1...1 {
                        let day = place.calendar.date(byAdding: .day, value: dayOffset, to: transition)!
                        let midnight = place.calendar.startOfDay(for: day)
                        selections += [-1.0, 0, 1].map { midnight.addingTimeInterval($0) }
                        selections.append(day)
                    }
                    for selection in selections {
                        let result = try await events(provider, place, selection)
                        for (event, sunrise) in [(result.sunrise, true), (result.sunset, false)] {
                            XCTAssertTrue(place.calendar.isDate(event, inSameDayAs: selection))
                            // Metamorphic check: the same event/local date in a
                            // zone fixed at its event-time offset must be identical.
                            // This isolates DST conversion from the solar formula.
                            let fixedZone = TimeZone(secondsFromGMT: place.zone.secondsFromGMT(for: event))!
                            var fixedCalendar = place.calendar; fixedCalendar.timeZone = fixedZone
                            var ymd = place.calendar.dateComponents([.year, .month, .day], from: selection)
                            ymd.hour = 12
                            let fixedDate = fixedCalendar.date(from: ymd)!
                            let fixed = await provider.sunEvents(for: fixedDate, coordinate: place.coordinate,
                                                                 timeZone: fixedZone, calendar: fixedCalendar)
                            let expected = try XCTUnwrap(fixed)
                            XCTAssertEqual(event.timeIntervalSince1970,
                                           (sunrise ? expected.sunrise : expected.sunset).timeIntervalSince1970,
                                           accuracy: 0.001, "\(place.zone.identifier) \(selection)")
                        }
                    }
                    cursor = transition.addingTimeInterval(1)
                }
                XCTAssertEqual(count, 2, "\(place.zone.identifier) \(year)")
            }
        }
    }

    func testNormalDatesPreservePreFixResultsIncludingFractionalOffsetsAndDateLine() async throws {
        // Captured from unmodified production code for local 2026-01-15.
        // These lock down preservation, not independent astronomical accuracy.
        let baseline: [(Double, Double)] = [
            (1768463983.618154, 1768493985.277567), (1768479485.834577, 1768513944.5971441),
            (1768461008.272295, 1768490464.8794258), (1768417181.5926692, 1768468145.4950516),
            (1768434316.815271, 1768475349.8724499), (1768427436.0484867, 1768463439.3592343),
            (1768438133.7911294, 1768477359.0885916), (1768439445.2413425, 1768477506.7903783),
            (1768415614.551742, 1768465933.0159788), (1768407745.0981822, 1768462106.4535387),
            (1768408695.9406586, 1768451976.9550624), (1768473706.6452155, 1768475102.3625054),
            (1768474555.9173281, 1768493884.0823927)
        ]
        let provider = CitySunEventProvider()
        for (place, expected) in zip(places, baseline) {
            let date = place.noon(2026, 1, 15)
            let result = try await events(provider, place, date)
            XCTAssertEqual(result.sunrise.timeIntervalSince1970, expected.0, accuracy: 0.001)
            XCTAssertEqual(result.sunset.timeIntervalSince1970, expected.1, accuracy: 0.001)
            XCTAssertTrue(place.calendar.isDate(result.sunrise, inSameDayAs: date))
            XCTAssertTrue(place.calendar.isDate(result.sunset, inSameDayAs: date))
        }
    }

    func testPolarEventsStayUnavailableAndNearMidnightKeepsLocalDate() async throws {
        let provider = CitySunEventProvider()
        let tromso = places[11]
        for month in [6, 12] {
            let result = await provider.sunEvents(for: tromso.noon(2026, month, 21), coordinate: tromso.coordinate,
                                                  timeZone: tromso.zone, calendar: tromso.calendar)
            XCTAssertNil(result, "Do not manufacture events during midnight sun or polar night")
            let resolution = await resolve(provider, tromso, tromso.noon(2026, month, 21))
            guard case .error = resolution else { return XCTFail("Preserve unavailable UI state") }
        }
        let reykjavik = places[12], date = reykjavik.noon(2026, 6, 21)
        let result = try await events(provider, reykjavik, date)
        XCTAssertEqual(reykjavik.calendar.component(.hour, from: result.sunset), 0)
        XCTAssertTrue(reykjavik.calendar.isDate(result.sunset, inSameDayAs: date))
        XCTAssertTrue(reykjavik.calendar.isDate(result.sunrise, inSameDayAs: date))
    }

    private func resolve(_ provider: CitySunEventProvider, _ place: Place, _ selected: Date) async -> DaylightResolution {
        await provider.seedSolarTestCoordinate(place.coordinate, id: place.zone.identifier)
        return await provider.resolve(for: SunRequest(cityID: place.zone.identifier, cityName: "Fixture",
            timeZoneID: place.zone.identifier, timeZone: place.zone, snapshotDate: selected,
            requestedAt: selected, isReferenceOffsetCity: false))
    }

    func testNextEventSelectionAcrossMidnightAndCitySwitches() async throws {
        let provider = CitySunEventProvider()
        for index in [0, 1, 3, 4, 5, 9, 10, 0] {
            let place = places[index]
            for month in [3, 10] {
                let noon = place.noon(2026, month, month == 3 ? 29 : 25)
                let midnight = place.calendar.startOfDay(for: noon)
                let today = try await events(provider, place, noon)
                for selection in [midnight.addingTimeInterval(-1), midnight, today.sunrise.addingTimeInterval(-1),
                                  today.sunrise.addingTimeInterval(1), today.sunset.addingTimeInterval(1)] {
                    let resolution = await resolve(provider, place, selection)
                    guard case .loaded(let presentation) = resolution else { XCTFail("Expected solar events"); continue }
                    XCTAssertGreaterThan(presentation.primaryDate, selection)
                    XCTAssertGreaterThan(presentation.secondaryDate, presentation.primaryDate)
                    let sameDay = place.calendar.isDate(presentation.primaryDate, inSameDayAs: selection)
                    let nextDay = place.calendar.date(byAdding: .day, value: 1, to: selection)!
                    XCTAssertTrue(sameDay || place.calendar.isDate(presentation.primaryDate, inSameDayAs: nextDay))
                    let expectedDay = try await events(provider, place, presentation.primaryDate)
                    XCTAssertEqual(presentation.primaryDate,
                                   presentation.primaryKind == .sunrise ? expectedDay.sunrise : expectedDay.sunset)
                }
            }
        }
    }

    func testSolarFormattingUsesBothHourPreferencesAndEventTimeOffset() async throws {
        let key = AppTimeFormatPreference.storageKey, saved = UserDefaults.standard.object(forKey: AppTimeFormatPreference.storageKey)
        defer { UserDefaults.standard.set(saved, forKey: key) }
        let london = places[0], provider = CitySunEventProvider()
        let result = try await events(provider, london, london.noon(2026, 3, 29))
        for preference in [AppTimeFormatPreference.twentyFourHour, .twelveHour] {
            UserDefaults.standard.set(preference.rawValue, forKey: key)
            for event in [result.sunrise, result.sunset] {
                let reference = DateFormatter()
                reference.locale = .autoupdatingCurrent; reference.timeZone = london.zone
                reference.dateFormat = preference == .twelveHour ? "hh:mm a" : "HH:mm"
                XCTAssertEqual(CityTimeFormatter.formatTime(event, in: london.zone),
                               reference.string(from: event).uppercased(with: .autoupdatingCurrent))
            }
        }
        XCTAssertEqual(london.zone.secondsFromGMT(for: result.sunrise), 3600)
    }

    func testFormattedSolarCardRetainsItsExistingGeometry() throws {
        let key = AppTimeFormatPreference.storageKey, saved = UserDefaults.standard.object(forKey: AppTimeFormatPreference.storageKey)
        defer { UserDefaults.standard.set(saved, forKey: key) }
        let city = City(name: "London", timeZoneID: "Europe/London")
        let date = instant("2026-03-29T18:27:23Z")
        let details = CityDetailsView(city: city, primaryCity: city, date: date,
                                      relativeOffsetMinutes: 0, cityViewPreference: .basic)
        for preference in [AppTimeFormatPreference.twelveHour, .twentyFourHour] {
            UserDefaults.standard.set(preference.rawValue, forKey: key)
            for width: CGFloat in [142, 158, 177, 250] {
                for dark in [false, true] {
                    let value = CityTimeFormatter.formatTime(date, in: city.timeZone)
                    let content = details.infoCard(title: "Sunset",
                        value: Text(value).font(.system(size: 32, weight: .medium)).tracking(-0.96),
                        secondary: "Sunrise at \(CityTimeFormatter.formatTime(date.addingTimeInterval(12 * 3600), in: city.timeZone))",
                        symbolName: "sunset.fill")
                        .minimumScaleFactor(0.65)
                        .environment(\.appTheme, dark ? .dark : .light)
                        .frame(width: width)
                    let renderer = ImageRenderer(content: content); renderer.scale = 3
                    let image = try XCTUnwrap(renderer.uiImage)
                    XCTAssertEqual(image.size.height, 157, accuracy: 0.1)
                    XCTAssertEqual(image.size.width, width, accuracy: 0.1)
                    let request = VNRecognizeTextRequest(); request.recognitionLevel = .accurate
                    try VNImageRequestHandler(cgImage: XCTUnwrap(image.cgImage)).perform([request])
                    let text = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
                    XCTAssertTrue(text.contains(value), "\(width) \(preference): \(text)")
                    if width == 158 && !dark {
                        let attachment = XCTAttachment(image: image)
                        attachment.name = "solar-card-\(preference)"; attachment.lifetime = .keepAlways; add(attachment)
                    }
                }
            }
        }
    }
}
