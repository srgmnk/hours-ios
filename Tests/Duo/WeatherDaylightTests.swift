import XCTest
import CoreLocation
import SwiftUI
@testable import MapHarness

extension CitySunEventProvider {
    func weatherTestSolarCacheCount() -> Int { solarDayCache.count }
}

// Intercept requests made by the production URLSession path.
// No live MapKit or Open-Meteo requests are needed for these integration tests.
nonisolated private final class WeatherFixtureProtocol: URLProtocol, @unchecked Sendable {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var captured: [URLRequest] = []
    nonisolated(unsafe) private static var delayFirst = false
    private let callbackLock = NSRecursiveLock()
    private var stopped = false

    static func reset(delayFirst: Bool = false) {
        lock.lock(); defer { lock.unlock() }
        captured = []; self.delayFirst = delayFirst
    }
    static var requests: [URLRequest] {
        lock.lock(); defer { lock.unlock() }; return captured
    }
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.lock.lock()
        Self.captured.append(request)
        let delay = Self.delayFirst && Self.captured.count == 1 ? 0.3 : 0.0
        Self.lock.unlock()
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [self] in
            callbackLock.lock(); defer { callbackLock.unlock() }
            guard !stopped else { return }
            let data = Data(#"{"current":{"temperature_2m":21,"apparent_temperature":20,"weather_code":0},"hourly":{"time":["2026-06-21T04:00","2026-06-21T12:00","2026-06-21T23:00"],"temperature_2m":[10,20,15],"apparent_temperature":[9,19,14],"weather_code":[2,3,1]}}"#.utf8)
            client?.urlProtocol(self, didReceive: HTTPURLResponse(url: request.url!, statusCode: 200,
                httpVersion: nil, headerFields: ["Content-Type": "application/json"])!, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        }
    }
    override func stopLoading() {
        callbackLock.lock(); defer { callbackLock.unlock() }; stopped = true
    }
}

@MainActor final class WeatherDaylightTests: XCTestCase {
    private func mockWeatherProvider(solar: CitySunEventProvider) -> CityWeatherProvider {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil
        configuration.protocolClasses = [WeatherFixtureProtocol.self]
        return CityWeatherProvider(sunEventProvider: solar, session: URLSession(configuration: configuration))
    }
    private struct Place {
        let name: String
        let zone: TimeZone
        let coordinate: CLLocationCoordinate2D
        init(_ name: String, _ zone: String, _ latitude: Double, _ longitude: Double) {
            self.name = name; self.zone = TimeZone(identifier: zone)!
            coordinate = .init(latitude: latitude, longitude: longitude)
        }
        var calendar: Calendar {
            var result = Calendar(identifier: .gregorian); result.timeZone = zone; return result
        }
        func date(_ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0) -> Date {
            calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute))!
        }
        func request(_ date: Date, requestedAt: Date? = nil) -> WeatherRequest {
            WeatherRequest(cityID: name, cityName: name, timeZoneID: zone.identifier,
                           coordinate: .init(latitude: coordinate.latitude, longitude: coordinate.longitude), snapshotDate: date,
                           requestedAt: requestedAt ?? date, isReferenceOffsetCity: false)
        }
    }
    private let places = [
        Place("Bangkok", "Asia/Bangkok", 13.7563, 100.5018),
        Place("Tokyo", "Asia/Tokyo", 35.6762, 139.6503),
        Place("London", "Europe/London", 51.5074, -0.1278),
        Place("New York", "America/New_York", 40.7128, -74.006),
        Place("Berlin", "Europe/Berlin", 52.52, 13.405),
        Place("Sydney", "Australia/Sydney", -33.8688, 151.2093),
        Place("Reykjavik", "Atlantic/Reykjavik", 64.1466, -21.9426),
        Place("Tromso", "Europe/Oslo", 69.6492, 18.9553),
        Place("Longyearbyen", "Europe/Oslo", 78.2232, 15.6469)
    ]

    private func assertDaylight(_ expected: Bool, _ provider: CitySunEventProvider, _ place: Place, _ date: Date,
                               file: StaticString = #filePath, line: UInt = #line) async {
        let result = await provider.isDaylight(at: date, coordinate: place.coordinate, in: place.zone)
        XCTAssertEqual(result, expected, "\(place.name) \(date)", file: file, line: line)
    }

    private func assertBoundaries(_ provider: CitySunEventProvider, _ place: Place, _ date: Date) async throws {
        let result = await provider.sunEvents(for: date, coordinate: place.coordinate,
                                              timeZone: place.zone, calendar: place.calendar)
        let events = try XCTUnwrap(result, place.name)
        // Card events only bracket a numerical crossing. Independent USNO fixtures
        // below establish accuracy; this helper checks second-level determinism.
        for (event, before, after) in [(events.sunrise, false, true), (events.sunset, true, false)] {
            func day(_ date: Date) -> Bool {
                SolarPosition(date: date).elevation(latitude: place.coordinate.latitude,
                    longitude: place.coordinate.longitude) >= -0.833
            }
            var low = event.addingTimeInterval(-600), high = event.addingTimeInterval(600)
            XCTAssertEqual(day(low), before); XCTAssertEqual(day(high), after)
            for _ in 0..<32 {
                let middle = low.addingTimeInterval(high.timeIntervalSince(low) / 2)
                if day(middle) == before { low = middle } else { high = middle }
            }
            await assertDaylight(before, provider, place, high.addingTimeInterval(-1))
            for _ in 0..<5 { await assertDaylight(after, provider, place, high) }
            await assertDaylight(after, provider, place, high.addingTimeInterval(1))
        }
    }

    func testSummerWinterAndExactEventBoundaries() async throws {
        let provider = CitySunEventProvider()
        for place in places.prefix(7) {
            for month in [6, 12] { try await assertBoundaries(provider, place, place.date(month, 21)) }
        }
        // Polar cities also have ordinary rise/set days in spring and autumn.
        for place in places.suffix(2) {
            for month in [3, 9] { try await assertBoundaries(provider, place, place.date(month, 21)) }
        }
    }

    func testSeasonalCasesThatDisagreeWithSixToEighteenRule() async {
        let provider = CitySunEventProvider()
        let cases = [(0, 6, 18, 30, true), (0, 12, 6, 15, false),
                     (1, 6, 4, 45, true), (2, 6, 5, 0, true), (2, 12, 8, 0, false),
                     (3, 6, 20, 0, true), (4, 6, 21, 0, true), (5, 12, 19, 30, true)]
        for (index, month, hour, minute, expected) in cases {
            let place = places[index]
            await assertDaylight(expected, provider, place, place.date(month, 21, hour, minute))
        }
    }

    func testActualDSTTransitionsAndAdjacentLocalDates() async throws {
        let provider = CitySunEventProvider()
        for index in [2, 3, 4, 5] {
            let place = places[index]
            var cursor = place.date(1, 1), count = 0
            while let transition = place.zone.nextDaylightSavingTimeTransition(after: cursor),
                  place.calendar.component(.year, from: transition) == 2026 {
                count += 1
                for offset in -1...1 {
                    try await assertBoundaries(provider, place,
                        place.calendar.date(byAdding: .day, value: offset, to: transition)!)
                }
                // These cities' transitions occur at night, on both sides of
                // the skipped/repeated clock interval.
                await assertDaylight(false, provider, place, transition.addingTimeInterval(-1))
                await assertDaylight(false, provider, place, transition.addingTimeInterval(1))
                cursor = transition.addingTimeInterval(1)
            }
            XCTAssertEqual(count, 2)
        }
    }

    func testMidnightRolloverAndSunsetBeforeSunriseClockTime() async {
        let provider = CitySunEventProvider()
        for place in places.prefix(6) {
            for month in [6, 12] {
                let midnight = place.date(month, 21, 0)
                for offset in [-1.0, 0, 1] {
                    await assertDaylight(false, provider, place, midnight.addingTimeInterval(offset))
                }
            }
        }
        let reykjavik = places[6]
        // Sunset is around 00:04, sunrise around 02:55 on this local date.
        await assertDaylight(true, provider, reykjavik, reykjavik.date(6, 21, 0, 1))
        await assertDaylight(false, provider, reykjavik, reykjavik.date(6, 21, 0, 10))
        await assertDaylight(false, provider, reykjavik, reykjavik.date(6, 21, 2))
        await assertDaylight(true, provider, reykjavik, reykjavik.date(6, 21, 23, 59))
        await assertDaylight(true, provider, reykjavik, reykjavik.date(6, 22, 0))
    }

    func testPolarDayAndNightWithoutInventingSolarEvents() async {
        let provider = CitySunEventProvider()
        // USNO rstt/oneday references retrieved 2026-11-11 at these coordinates:
        // https://aa.usno.navy.mil/data/api — June 21 continuously above the
        // horizon; December 21 continuously below it for both cities.
        for place in places.suffix(2) {
            for (month, expected) in [(6, true), (12, false)] {
                let events = await provider.sunEvents(for: place.date(month, 21), coordinate: place.coordinate,
                                                      timeZone: place.zone, calendar: place.calendar)
                XCTAssertNil(events)
                for hour in 0..<24 {
                    await assertDaylight(expected, provider, place, place.date(month, 21, hour))
                }
            }
        }
    }

    func testInvalidCoordinatesUseDeterministicNightFallback() async {
        let provider = CitySunEventProvider(), place = places[0]
        for coordinate in [CLLocationCoordinate2D(latitude: .nan, longitude: 0),
                           CLLocationCoordinate2D(latitude: 91, longitude: 0)] {
            for hour in [0, 12] {
                let result = await provider.isDaylight(at: place.date(6, 21, hour), coordinate: coordinate, in: place.zone)
                XCTAssertFalse(result)
            }
        }
        let count = await provider.weatherTestSolarCacheCount()
        XCTAssertEqual(count, 0)
    }

    func testIconClassificationDoesNotPopulateOrAlterCardSolarCache() async {
        let provider = CitySunEventProvider(), place = places[2], date = places[2].date(6, 21)
        for hour in 0..<24 {
            _ = await provider.isDaylight(at: place.date(6, 21, hour), coordinate: place.coordinate, in: place.zone)
        }
        var count = await provider.weatherTestSolarCacheCount(); XCTAssertEqual(count, 0)
        let original = await provider.sunEvents(for: date, coordinate: place.coordinate,
            timeZone: place.zone, calendar: place.calendar)
        for zone in [place.zone, TimeZone(secondsFromGMT: 0)!, TimeZone(identifier: "Pacific/Chatham")!] {
            _ = await provider.isDaylight(at: date, coordinate: place.coordinate, in: zone)
        }
        let unchanged = await provider.sunEvents(for: date, coordinate: place.coordinate,
            timeZone: place.zone, calendar: place.calendar)
        XCTAssertEqual(original?.sunrise, unchanged?.sunrise)
        XCTAssertEqual(original?.sunset, unchanged?.sunset)
        count = await provider.weatherTestSolarCacheCount(); XCTAssertEqual(count, 1)
        for day in 1...31 {
            _ = await provider.sunEvents(for: place.date(7, day), coordinate: place.coordinate,
                timeZone: place.zone, calendar: place.calendar)
            count = await provider.weatherTestSolarCacheCount(); XCTAssertLessThanOrEqual(count, 16)
        }
    }

    func testInvalidDatesAndCoordinatesAndTimeZoneInvariance() async {
        let provider = CitySunEventProvider(), place = places[2]
        for seconds in [Double.nan, .infinity, -.infinity] {
            await assertDaylight(false, provider, place, Date(timeIntervalSinceReferenceDate: seconds))
        }
        for coordinate in [CLLocationCoordinate2D(latitude: 0, longitude: .nan),
                           .init(latitude: .infinity, longitude: 0),
                           .init(latitude: 0, longitude: 181)] {
            let day = await provider.isDaylight(at: place.date(6, 21), coordinate: coordinate, in: place.zone)
            XCTAssertFalse(day)
        }
        for month in [3, 6, 9, 12] {
            for hour in [0, 6, 12, 18, 23] {
                let date = place.date(month, 21, hour)
                let expected = await provider.isDaylight(at: date, coordinate: place.coordinate, in: place.zone)
                for zone in ["Asia/Kathmandu", "Australia/Lord_Howe", "Pacific/Chatham", "America/New_York"] {
                    let actual = await provider.isDaylight(at: date, coordinate: place.coordinate, in: TimeZone(identifier: zone)!)
                    XCTAssertEqual(actual, expected)
                }
            }
        }
    }

    func testFourConfirmedPolarFailuresAgainstUSNO() async {
        let provider = CitySunEventProvider()
        let longyearbyen = Place("Longyearbyen", "Arctic/Longyearbyen", 78.22334, 15.64689)
        let utqiagvik = Place("Utqiagvik", "America/Anchorage", 71.2906, -156.7886)
        // USNO rstt/oneday, 2026, at the exact coordinates above:
        // August 25 late sunset 23:56; February 15 daylight 11:58–12:27.
        // May 11 continuously above; November 19 continuously below the horizon.
        // https://aa.usno.navy.mil/api/rstt/oneday?date=2026-08-25&coords=78.22334,15.64689&tz=2
        // https://aa.usno.navy.mil/api/rstt/oneday?date=2026-02-15&coords=78.22334,15.64689&tz=1
        // https://aa.usno.navy.mil/api/rstt/oneday?date=2026-05-11&coords=71.2906,-156.7886&tz=-8
        // https://aa.usno.navy.mil/api/rstt/oneday?date=2026-11-19&coords=71.2906,-156.7886&tz=-9
        for (hour, minute, expected) in [(23, 54, true), (23, 58, false)] {
            await assertDaylight(expected, provider, longyearbyen, longyearbyen.date(8, 25, hour, minute))
        }
        for (hour, minute, expected) in [(11, 56, false), (12, 0, true), (12, 25, true), (12, 29, false)] {
            await assertDaylight(expected, provider, longyearbyen, longyearbyen.date(2, 15, hour, minute))
        }
        for (month, day, expected) in [(5, 11, true), (11, 19, false)] {
            let start = utqiagvik.date(month, day, 0)
            for minute in -1...1440 {
                await assertDaylight(expected, provider, utqiagvik, start.addingTimeInterval(Double(minute * 60)))
            }
        }
        for seconds in [-1.0, 0, 1] {
            await assertDaylight(false, provider, longyearbyen, longyearbyen.date(8, 26, 0).addingTimeInterval(seconds))
        }
    }

    func testIndependentUSNOBoundariesAcrossSixteenLocations() async {
        // Minute-rounded USNO rstt/oneday references retrieved 2026-11-11.
        // Reproduce via https://aa.usno.navy.mil/api/rstt/oneday?date=YYYY-MM-DD&coords=LAT,LON&tz=OFFSET
        // UTC epochs below retain each response's local-date offset. This includes
        // solstices, equinoxes, DST dates and each normal city's largest audited shift.
        let fixtures = [
            Place("Tromso", "Europe/Oslo", 69.6489, 18.95508),
            Place("Longyearbyen", "Arctic/Longyearbyen", 78.22334, 15.64689),
            Place("Reykjavik", "Atlantic/Reykjavik", 64.13548, -21.89541),
            Place("Murmansk", "Europe/Moscow", 68.96778, 33.09922),
            Place("Ushuaia", "America/Argentina/Ushuaia", -54.81084, -68.31591),
            Place("London", "Europe/London", 51.50853, -0.12574),
            Place("New York", "America/New_York", 40.71427, -74.00597),
            Place("Berlin", "Europe/Berlin", 52.52437, 13.41053),
            Place("Sydney", "Australia/Sydney", -33.86785, 151.20732),
            Place("Bangkok", "Asia/Bangkok", 13.75398, 100.50144),
            Place("Tokyo", "Asia/Tokyo", 35.6895, 139.69171),
            Place("Kathmandu", "Asia/Kathmandu", 27.70169, 85.3206),
            Place("Rovaniemi", "Europe/Helsinki", 66.5039, 25.7294),
            Place("Utqiagvik", "America/Anchorage", 71.2906, -156.7886),
            Place("Lord Howe", "Australia/Lord_Howe", -31.55, 159.0833),
            Place("Chatham", "Pacific/Chatham", -43.95, -176.55)
        ]
        // place index | reference UTC seconds | R(ise)/S(et)
        let references = """
        1|1771153080|R
        1|1771154820|S
        1|1771236840|R
        1|1771243860|S
        1|1776384480|R
        1|1776463920|S
        1|1776469140|R
        1|1787610540|S
        1|1787614380|R
        1|1787694960|S
        1|1787702700|R
        1|1787780040|S
        1|1793009520|R
        1|1793012940|S
        0|1768472940|R
        0|1768475940|S
        0|1778887920|R
        0|1778968920|S
        0|1778973480|R
        0|1779056820|S
        0|1779058380|R
        0|1785018960|S
        0|1785020760|R
        0|1795774800|R
        0|1795776180|S
        2|1781578620|R
        2|1781654460|S
        2|1781664960|R
        2|1782000180|S
        2|1782010500|R
        2|1782604860|S
        2|1782615660|R
        2|1797852120|R
        2|1797866940|S
        12|1780696800|S
        12|1780698660|R
        12|1783375500|S
        12|1783377540|R
        12|1797844080|R
        12|1797852120|S
        13|1769120640|R
        13|1769122500|S
        13|1769205540|R
        13|1769210460|S
        13|1785664800|S
        13|1785668880|R
        3|1768123980|R
        3|1768126740|S
        3|1779312180|S
        3|1779314700|R
        3|1784756040|S
        3|1784758500|R
        3|1796116920|R
        3|1796118660|S
        4|1782046740|R
        4|1782072660|S
        4|1797839460|R
        4|1797901860|S
        5|1774762980|R
        5|1774808940|S
        5|1792910520|R
        5|1792946820|S
        6|1772968740|R
        6|1773010500|S
        6|1793532360|R
        6|1793569920|S
        7|1774759680|R
        7|1774805700|S
        7|1792907400|R
        7|1792943400|S
        8|1775333400|R
        8|1775375100|S
        8|1791055740|R
        8|1791100800|S
        9|1781995920|R
        9|1782042480|S
        10|1781983560|R
        10|1782036000|S
        11|1781997840|R
        11|1782047820|S
        14|1775331420|R
        14|1775373300|S
        14|1791053880|R
        14|1791098820|S
        15|1775326020|R
        15|1775367000|S
        15|1790443620|R
        15|1790488080|S
        0|1773981840|R
        0|1774026120|S
        0|1790051040|R
        0|1790095680|S
        0|1790137680|R
        0|1790181780|S
        1|1773982320|R
        1|1774027320|S
        1|1790051280|R
        1|1790096880|S
        1|1790138100|R
        1|1790182860|S
        2|1773991680|R
        2|1774035780|S
        2|1790061000|R
        2|1790105280|S
        2|1790147580|R
        2|1790191500|S
        3|1773978480|R
        3|1774022640|S
        3|1790047680|R
        3|1790092260|S
        3|1790134260|R
        3|1790178420|S
        4|1774002900|R
        4|1774046760|S
        4|1790072520|R
        4|1790116260|S
        4|1790158740|R
        4|1790202780|S
        5|1773986580|R
        5|1774030380|S
        5|1782013380|R
        5|1782073260|S
        5|1790056020|R
        5|1790099940|S
        5|1790142480|R
        5|1790186220|S
        5|1797840240|R
        5|1797868380|S
        6|1774004340|R
        6|1774048080|S
        6|1782033900|R
        6|1782088260|S
        6|1790073840|R
        6|1790117580|S
        6|1790160300|R
        6|1790203860|S
        6|1797855420|R
        6|1797888720|S
        7|1773983340|R
        7|1774027140|S
        7|1782009780|R
        7|1782070380|S
        7|1790052720|R
        7|1790096700|S
        7|1790139240|R
        7|1790182980|S
        7|1797837300|R
        7|1797864840|S
        8|1773950280|R
        8|1773994020|S
        8|1781989200|R
        8|1782024840|S
        8|1790019900|R
        8|1790063460|S
        8|1790106240|R
        8|1790149920|S
        8|1797792060|R
        8|1797843900|S
        9|1773962520|R
        9|1774006140|S
        9|1790032020|R
        9|1790075640|S
        9|1790118420|R
        9|1790162040|S
        9|1797809760|R
        9|1797850500|S
        10|1773953160|R
        10|1773996780|S
        10|1790022540|R
        10|1790066340|S
        10|1790109000|R
        10|1790152620|S
        10|1797803220|R
        10|1797838260|S
        11|1773966180|R
        11|1774009800|S
        11|1790035620|R
        11|1790079360|S
        11|1790122080|R
        11|1790165640|S
        11|1797815100|R
        11|1797852480|S
        12|1773980280|R
        12|1774024380|S
        12|1790049540|R
        12|1790093940|S
        12|1790136120|R
        12|1790180100|S
        13|1774023840|R
        13|1774068480|S
        13|1790093280|R
        13|1790137740|S
        13|1790179920|R
        13|1790223840|S
        14|1773948420|R
        14|1773992100|S
        14|1781986980|R
        14|1782023280|S
        14|1790018040|R
        14|1790061600|S
        14|1790104380|R
        14|1790148000|S
        14|1797790500|R
        14|1797841680|S
        15|1773942480|R
        15|1773986340|S
        15|1781983260|R
        15|1782015300|S
        15|1790012160|R
        15|1790055720|S
        15|1790098500|R
        15|1790142240|S
        15|1797782340|R
        15|1797838140|S
        4|1773224220|R
        4|1773270480|S
        5|1789018020|R
        5|1789064820|S
        6|1789468620|R
        6|1789513500|S
        7|1788928200|R
        7|1788975360|S
        8|1773518040|R
        8|1773562440|S
        9|1789513620|R
        9|1789557540|S
        10|1789071600|R
        10|1789116900|S
        11|1789430640|R
        11|1789475040|S
        14|1773602640|R
        14|1773646800|S
        15|1791306540|R
        15|1791352800|S
        """
        let provider = CitySunEventProvider()
        let polar = Set(["Tromso", "Longyearbyen", "Reykjavik", "Murmansk", "Rovaniemi", "Utqiagvik"])
        var count = 0
        for row in references.split(separator: "\n") {
            let values = row.split(separator: "|")
            let place = fixtures[Int(values[0])!]
            let event = Date(timeIntervalSince1970: Double(values[1])!)
            let rising = values[2] == "R"
            // Independent minute rounding and shallow polar angles preclude an
            // exact-second truth assertion. Normal references agree at ±1 minute;
            // all sampled high-latitude references agree at ±2 minutes.
            let offsets = polar.contains(place.name) ? [-600, -120, 120, 600] : [-600, -120, -60, 60, 120, 600]
            for offset in offsets {
                await assertDaylight(offset > 0 ? rising : !rising, provider, place,
                    event.addingTimeInterval(Double(offset)))
            }
            count += 1
        }
        XCTAssertEqual(count, 234)
    }

    func testAllWeatherConditionIconsAndTitlesRemainUnchanged() async {
        let provider = CityWeatherProvider(sunEventProvider: CitySunEventProvider())
        let groups: [([Int], String, String, String)] = [
            ([0], "Clear", "sun.max.fill", "moon.stars.fill"),
            ([1], "Mainly clear", "cloud.sun.fill", "cloud.moon.fill"),
            ([2], "Partly cloudy", "cloud.sun.fill", "cloud.moon.fill"),
            ([3], "Cloudy", "cloud.fill", "cloud.fill"),
            ([45, 48], "Fog", "cloud.fog.fill", "cloud.fog.fill"),
            ([51, 53, 55], "Drizzle", "cloud.drizzle.fill", "cloud.drizzle.fill"),
            ([56, 57], "Freezing drizzle", "cloud.drizzle.fill", "cloud.drizzle.fill"),
            ([61, 63, 65, 66, 67, 80, 81, 82], "Rain", "cloud.rain.fill", "cloud.rain.fill"),
            ([71, 73, 75, 77, 85, 86], "Snow", "cloud.snow.fill", "cloud.snow.fill"),
            ([95, 96, 99], "Thunderstorm", "cloud.bolt.rain.fill", "cloud.bolt.rain.fill"),
            ([-1, 1000], "Unknown", "cloud.fill", "cloud.fill")
        ]
        for (codes, title, day, night) in groups {
            for code in codes {
                for daylight in [false, true] {
                    let result = await provider.makeCardContent(temperatureCelsius: 21, apparentTemperatureCelsius: 20,
                                                               weatherCode: code, isDaylight: daylight)
                    XCTAssertEqual(result.symbolName, daylight ? day : night)
                    XCTAssertEqual(result.title, title)
                    XCTAssertEqual(result.value, "21°C")
                    XCTAssertEqual(result.secondary, "Feels like 20°C")
                }
            }
        }
    }

    func testProductionWeatherRequestsUseSelectedInstantAndCoordinatesInBothHourModes() async throws {
        WeatherFixtureProtocol.reset()
        let key = AppTimeFormatPreference.storageKey, saved = UserDefaults.standard.object(forKey: AppTimeFormatPreference.storageKey)
        defer { UserDefaults.standard.set(saved, forKey: key) }
        let solar = CitySunEventProvider(), provider = mockWeatherProvider(solar: solar)
        var fetchedCities: Set<String> = []
        for preference in [AppTimeFormatPreference.twelveHour, .twentyFourHour] {
            UserDefaults.standard.set(preference.rawValue, forKey: key)
            // Switch time, city (including two distinct places sharing a zone),
            // and back to the first city. The fixture's weather code stays clear.
            for (index, month, hour, day) in [(2, 6, 5, true), (2, 12, 8, false), (0, 6, 12, true),
                                             (7, 6, 0, true), (8, 12, 12, false), (2, 6, 23, false)] {
                let place = places[index], date = places[index].date(month, 21, hour)
                let resolution = await provider.resolve(for: place.request(date))
                guard case .loaded(let content) = resolution else { XCTFail("Expected fixture response"); continue }
                XCTAssertEqual(content.symbolName, day ? "sun.max.fill" : "moon.stars.fill")
                fetchedCities.insert(place.name)
                XCTAssertEqual(WeatherFixtureProtocol.requests.count, fetchedCities.count)
                let url = try XCTUnwrap(WeatherFixtureProtocol.requests.compactMap(\.url).first { url in
                    let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
                    return query.contains(URLQueryItem(name: "latitude", value: String(place.coordinate.latitude)))
                        && query.contains(URLQueryItem(name: "longitude", value: String(place.coordinate.longitude)))
                })
                let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
                let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })
                XCTAssertEqual(url.host, "api.open-meteo.com"); XCTAssertEqual(url.path, "/v1/forecast")
                XCTAssertEqual(query["latitude"], String(place.coordinate.latitude))
                XCTAssertEqual(query["longitude"], String(place.coordinate.longitude))
                XCTAssertEqual(query["timezone"], place.zone.identifier)
                XCTAssertEqual(query["current"], "temperature_2m,apparent_temperature,weather_code")
                XCTAssertEqual(query["hourly"], query["current"])
                XCTAssertEqual(query["past_days"], "1"); XCTAssertEqual(query["forecast_days"], "2")
                XCTAssertEqual(query.count, 7)
            }
        }
        let place = places[2], date = places[2].date(6, 21, 23)
        let hourly = await provider.resolve(for: place.request(date, requestedAt: date.addingTimeInterval(600)))
        guard case .loaded(let content) = hourly else { return XCTFail("Expected hourly fixture") }
        XCTAssertEqual(content.symbolName, "cloud.moon.fill"); XCTAssertEqual(content.value, "15°C")
        XCTAssertEqual(WeatherFixtureProtocol.requests.count, fetchedCities.count)
    }

    func testCancelledOldRequestCannotReturnLoadedIconAfterNewSelection() async throws {
        WeatherFixtureProtocol.reset(delayFirst: true)
        let provider = mockWeatherProvider(solar: CitySunEventProvider())
        let london = places[2], bangkok = places[0]
        let old = Task { await provider.resolve(for: london.request(london.date(6, 21, 5))) }
        for _ in 0..<100 {
            if !WeatherFixtureProtocol.requests.isEmpty { break }
            try await Task.sleep(for: .milliseconds(10))
        }
        XCTAssertEqual(WeatherFixtureProtocol.requests.count, 1)
        old.cancel()
        let latest = await provider.resolve(for: bangkok.request(bangkok.date(6, 21, 23)))
        guard case .loaded(let content) = latest else { return XCTFail("Expected new selection") }
        XCTAssertEqual(content.symbolName, "moon.stars.fill")
        let oldResult = await old.value
        if case .loaded = oldResult { XCTFail("Cancelled response must not carry an old icon") }
        XCTAssertEqual(WeatherFixtureProtocol.requests.count, 2)
    }
}
