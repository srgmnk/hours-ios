import XCTest
import CoreLocation
import SwiftUI
@testable import MapHarness

extension CityWeatherProvider {
    func seedWeatherTestCoordinate(_ coordinate: CLLocationCoordinate2D, id: String) {
        coordinateCache[id] = CoordinatePoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}

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
            WeatherRequest(cityID: name, cityName: name, timeZoneID: zone.identifier, snapshotDate: date,
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
        for (event, before, at) in [(events.sunrise, false, true), (events.sunset, true, false)] {
            await assertDaylight(before, provider, place, event.addingTimeInterval(-1))
            await assertDaylight(at, provider, place, event)
            await assertDaylight(at, provider, place, event.addingTimeInterval(1))
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

    func testSolarCacheIsSharedBoundedAndSeparatedByCoordinatesDateAndZone() async {
        let provider = CitySunEventProvider(), place = places[2], date = places[2].date(6, 21)
        _ = await provider.sunEvents(for: date, coordinate: place.coordinate, timeZone: place.zone, calendar: place.calendar)
        for hour in 0..<24 {
            _ = await provider.isDaylight(at: place.date(6, 21, hour), coordinate: place.coordinate, in: place.zone)
        }
        var count = await provider.weatherTestSolarCacheCount(); XCTAssertEqual(count, 1)
        _ = await provider.isDaylight(at: place.date(6, 22), coordinate: place.coordinate, in: place.zone)
        _ = await provider.isDaylight(at: date, coordinate: places[0].coordinate, in: place.zone)
        _ = await provider.isDaylight(at: date, coordinate: place.coordinate, in: places[0].zone)
        count = await provider.weatherTestSolarCacheCount(); XCTAssertEqual(count, 4)
        for day in 1...31 {
            _ = await provider.isDaylight(at: place.date(7, day), coordinate: place.coordinate, in: place.zone)
            count = await provider.weatherTestSolarCacheCount(); XCTAssertLessThanOrEqual(count, 16)
        }
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
        for place in places { await provider.seedWeatherTestCoordinate(place.coordinate, id: place.name) }
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
        for place in [london, bangkok] { await provider.seedWeatherTestCoordinate(place.coordinate, id: place.name) }
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
