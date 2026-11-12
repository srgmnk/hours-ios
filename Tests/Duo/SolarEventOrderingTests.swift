import XCTest
import CoreLocation
@testable import MapHarness

@MainActor final class SolarEventOrderingTests: XCTestCase {
    private struct Place {
        let name: String
        let zone: TimeZone
        let coordinate: LocalCityCoordinates.Coordinate
        init(_ name: String, _ zone: String, _ latitude: Double, _ longitude: Double) {
            self.name = name; self.zone = TimeZone(identifier: zone)!
            coordinate = .init(latitude: latitude, longitude: longitude)
        }
        var calendar: Calendar {
            var value = Calendar(identifier: .gregorian); value.timeZone = zone; return value
        }
        func local(_ day: String, _ time: String = "00:00:00") -> Date {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = zone; formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return formatter.date(from: "\(day) \(time)")!
        }
    }
    private let reykjavik = Place("Reykjavik", "Atlantic/Reykjavik", 64.13548, -21.89541)
    private func resolve(_ provider: CitySunEventProvider, _ place: Place, _ selected: Date) async -> DaylightResolution {
        await provider.resolve(for: SunRequest(cityID: place.name, cityName: place.name,
            timeZoneID: place.zone.identifier, coordinate: place.coordinate, timeZone: place.zone,
            snapshotDate: selected, requestedAt: selected, isReferenceOffsetCity: false))
    }
    private func loaded(_ result: DaylightResolution, file: StaticString = #filePath, line: UInt = #line) throws -> SunPresentation {
        guard case .loaded(let value) = result else {
            XCTFail("Expected an unambiguous future pair", file: file, line: line)
            throw URLError(.cannotParseResponse)
        }
        return value
    }

    func testSunsetBeforeSunriseMatchesIndependentUSNOReferences() async throws {
        // USNO one-day API references retrieved 2026-11-11 at the exact fixture coordinates:
        // https://aa.usno.navy.mil/api/rstt/oneday?date=2026-06-21&coords=64.13548,-21.89541&tz=0
        // Tromso: 2026-05-18, tz=2; Rovaniemi: 2026-06-06, tz=3; Murmansk: 2026-05-21, tz=3.
        // Tolerances retain the independently measured existing approximation errors;
        // this correction changes selection, not the astronomical event timestamps.
        let cases: [(Place, String, String, String, Double)] = [
            (reykjavik, "2026-06-21", "00:03:00", "02:55:00", 60),
            (Place("Tromso", "Europe/Oslo", 69.6489, 18.95508), "2026-05-18", "00:27:00", "00:53:00", 7 * 60),
            (Place("Rovaniemi", "Europe/Helsinki", 66.5039, 25.7294), "2026-06-06", "01:00:00", "01:31:00", 4 * 60),
            (Place("Murmansk", "Europe/Moscow", 68.96778, 33.09922), "2026-05-21", "00:23:00", "01:05:00", 5 * 60)
        ]
        let provider = CitySunEventProvider()
        for (place, day, sunset, sunrise, tolerance) in cases {
            let selected = place.local(day)
            let value = try loaded(await resolve(provider, place, selected))
            XCTAssertEqual(value.primaryKind, .sunset, place.name)
            XCTAssertEqual(value.secondaryKind, .sunrise, place.name)
            XCTAssertEqual(value.primaryDate.timeIntervalSince1970, place.local(day, sunset).timeIntervalSince1970, accuracy: tolerance)
            XCTAssertEqual(value.secondaryDate.timeIntervalSince1970, place.local(day, sunrise).timeIntervalSince1970, accuracy: tolerance)
            XCTAssertGreaterThan(value.primaryDate, selected)
            XCTAssertGreaterThan(value.secondaryDate, value.primaryDate)
        }
    }

    func testReykjavikAfterSunsetDoesNotReuseElapsedSecondaryEvent() async throws {
        let provider = CitySunEventProvider(), midnight = reykjavik.local("2026-06-21")
        let before = try loaded(await resolve(provider, reykjavik, midnight))
        for selected in [before.primaryDate, before.primaryDate.addingTimeInterval(1), reykjavik.local("2026-06-21", "00:04:00")] {
            let after = try loaded(await resolve(provider, reykjavik, selected))
            XCTAssertEqual(after.primaryKind, .sunrise)
            XCTAssertEqual(after.primaryDate, before.secondaryDate)
            XCTAssertEqual(after.secondaryKind, .sunset)
            XCTAssertTrue(reykjavik.calendar.isDate(after.secondaryDate, inSameDayAs: reykjavik.local("2026-06-22")))
            XCTAssertGreaterThan(after.secondaryDate, after.primaryDate)
        }
    }

    func testExactAndOneSecondBoundariesUseStrictlyFutureInstants() async throws {
        let provider = CitySunEventProvider(), origin = Date(timeIntervalSince1970: 1_800_000_000)
        let candidates: [CitySunEventProvider.SolarEvent] = [
            .init(kind: .sunset, date: origin.addingTimeInterval(30)),
            .init(kind: .sunset, date: origin.addingTimeInterval(10)),
            .init(kind: .sunrise, date: origin.addingTimeInterval(40)),
            .init(kind: .sunrise, date: origin.addingTimeInterval(20))
        ]
        for (offset, primary, secondary) in [(9.0, 10.0, 20.0), (10, 20, 30), (11, 20, 30),
                                              (19, 20, 30), (20, 30, 40), (21, 30, 40)] {
            let result = await provider.nextPresentation(after: origin.addingTimeInterval(offset), candidates: candidates)
            let value = try XCTUnwrap(result)
            XCTAssertEqual(value.primaryDate, origin.addingTimeInterval(primary))
            XCTAssertEqual(value.secondaryDate, origin.addingTimeInterval(secondary))
        }
    }

    func testMissingCoincidentAndConsecutiveSameKindCandidatesStayUnavailable() async {
        let provider = CitySunEventProvider(), origin = Date(timeIntervalSince1970: 1_800_000_000)
        func event(_ kind: SunEventKind, _ seconds: Double) -> CitySunEventProvider.SolarEvent {
            .init(kind: kind, date: origin.addingTimeInterval(seconds))
        }
        let invalid: [[CitySunEventProvider.SolarEvent]] = [
            [], [event(.sunrise, 10)], [event(.sunset, 10)],
            [event(.sunrise, -10), event(.sunset, 10)],
            [event(.sunset, 10), event(.sunset, 20), event(.sunrise, 30)],
            [event(.sunrise, 10), event(.sunrise, 20), event(.sunset, 30)],
            [event(.sunrise, 10), event(.sunset, 10)],
            [event(.sunrise, 10), event(.sunrise, 10), event(.sunset, 20)],
            [event(.sunrise, 10), event(.sunset, 20), event(.sunrise, 20)],
            [event(.sunrise, .nan), event(.sunset, 20)]
        ]
        for candidates in invalid {
            let result = await provider.nextPresentation(after: origin, candidates: candidates)
            XCTAssertNil(result)
        }
        let onePerDay = await provider.nextPresentation(after: origin,
            candidates: [event(.sunset, 10), event(.sunrise, 86_500)])
        XCTAssertNotNil(onePerDay, "A pair need not originate on the same calendar date")
    }

    func testActualContradictoryAndPolarCandidatesDoNotSearchBeyondTomorrow() async {
        let provider = CitySunEventProvider()
        let tromso = Place("Tromso", "Europe/Oslo", 69.6489, 18.95508)
        let longyearbyen = Place("Longyearbyen", "Arctic/Longyearbyen", 78.22334, 15.64689)
        for (place, selected) in [(reykjavik, reykjavik.local("2026-06-16", "12:00:00")),
                                  (tromso, tromso.local("2026-05-18", "12:00:00")),
                                  (tromso, tromso.local("2026-06-21", "12:00:00")),
                                  (longyearbyen, longyearbyen.local("2026-02-15", "12:00:00"))] {
            guard case .error = await resolve(provider, place, selected) else {
                return XCTFail("Do not skip conflicting sunsets, invent polar events, or reach beyond the bounded window")
            }
        }
    }

    func testMidnightDateRolloverUsesTheNextChronologicalEvent() async throws {
        let provider = CitySunEventProvider(), midnight = reykjavik.local("2026-06-21")
        let before = try loaded(await resolve(provider, reykjavik, midnight.addingTimeInterval(-1)))
        let after = try loaded(await resolve(provider, reykjavik, midnight))
        XCTAssertEqual(before.primaryKind, .sunset)
        XCTAssertEqual(before.primaryDate, after.primaryDate)
        XCTAssertEqual(before.secondaryDate, after.secondaryDate)
    }

    func testWindowUsesAtMostTwoCachedDaysAndReusesThemOnReopening() async throws {
        let provider = CitySunEventProvider(), selected = reykjavik.local("2026-06-21")
        let initial = try loaded(await resolve(provider, reykjavik, selected))
        var count = await provider.weatherTestSolarCacheCount(); XCTAssertEqual(count, 1)
        for _ in 0..<20 {
            _ = try loaded(await resolve(provider, reykjavik, initial.primaryDate.addingTimeInterval(1)))
        }
        count = await provider.weatherTestSolarCacheCount(); XCTAssertEqual(count, 2)
        _ = try loaded(await resolve(provider, reykjavik, selected))
        count = await provider.weatherTestSolarCacheCount(); XCTAssertEqual(count, 2)
    }

    func testNormalCityEquivalenceAtSolsticesAndActualDSTTransitions() async throws {
        let places = [
            Place("London", "Europe/London", 51.5074, -0.1278),
            Place("New York", "America/New_York", 40.7128, -74.006),
            Place("Berlin", "Europe/Berlin", 52.52, 13.405),
            Place("Sydney", "Australia/Sydney", -33.8688, 151.2093),
            Place("Bangkok", "Asia/Bangkok", 13.7563, 100.5018),
            Place("Tokyo", "Asia/Tokyo", 35.6762, 139.6503),
            Place("Kathmandu", "Asia/Kathmandu", 27.7172, 85.324),
            Place("Lord Howe", "Australia/Lord_Howe", -31.55, 159.0833),
            Place("Chatham", "Pacific/Chatham", -43.95, -176.55),
            Place("Ushuaia", "America/Argentina/Ushuaia", -54.81084, -68.31591)
        ]
        let provider = CitySunEventProvider()
        for place in places {
            let calendar = place.calendar
            var dates = Set([place.local("2026-06-21"), place.local("2026-12-21")])
            var cursor = place.local("2026-01-01")
            while let transition = place.zone.nextDaylightSavingTimeTransition(after: cursor),
                  transition < place.local("2027-01-01") {
                for offset in -1...1 {
                    dates.insert(calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: transition))!)
                }
                cursor = transition.addingTimeInterval(1)
            }
            for day in dates.sorted() {
                let coordinate = CLLocationCoordinate2D(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
                let events = await provider.sunEvents(for: day, coordinate: coordinate, timeZone: place.zone, calendar: calendar)
                let today = try XCTUnwrap(events)
                let nextDate = calendar.date(byAdding: .day, value: 1, to: day)!
                let nextEvents = await provider.sunEvents(for: nextDate, coordinate: coordinate, timeZone: place.zone, calendar: calendar)
                let tomorrow = try XCTUnwrap(nextEvents)
                // These ordinary-city fixtures have the conventional order. Preserve
                // the old card's exact timestamps, not merely approximate formatting.
                XCTAssertLessThan(today.sunrise, today.sunset)
                for (selected, primary, secondary) in [
                    (day, today.sunrise, today.sunset),
                    (today.sunrise.addingTimeInterval(-1), today.sunrise, today.sunset),
                    (today.sunrise, today.sunset, tomorrow.sunrise),
                    (today.sunset.addingTimeInterval(-1), today.sunset, tomorrow.sunrise),
                    (today.sunset, tomorrow.sunrise, tomorrow.sunset),
                    (today.sunset.addingTimeInterval(1), tomorrow.sunrise, tomorrow.sunset)
                ] {
                    let value = try loaded(await resolve(provider, place, selected))
                    XCTAssertEqual(value.primaryDate, primary, place.name)
                    XCTAssertEqual(value.secondaryDate, secondary, place.name)
                }
            }
        }
    }

    func testCancelledSelectionDoesNotPopulateSolarCache() async {
        let provider = CitySunEventProvider()
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return await resolve(provider, reykjavik, reykjavik.local("2026-06-21"))
        }
        guard case .error = await task.value else { return XCTFail("Cancelled selection must remain unavailable") }
        let count = await provider.weatherTestSolarCacheCount(); XCTAssertEqual(count, 0)
    }
}
