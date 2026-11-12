import XCTest
import SwiftUI
import CoreLocation
import Vision
@testable import MapHarness

nonisolated private final class WeatherTestClock: @unchecked Sendable {
    private let lock = NSLock()
    private var date: Date
    init(_ date: Date) { self.date = date }
    func now() -> Date { lock.lock(); defer { lock.unlock() }; return date }
    func advance(_ seconds: TimeInterval) { lock.lock(); defer { lock.unlock() }; date.addTimeInterval(seconds) }
}

nonisolated private final class CachedWeatherProtocol: URLProtocol, @unchecked Sendable {
    struct Reply: Sendable {
        var data = CachedWeatherProtocol.body()
        var status = 200
        var error: URLError.Code?
        var delay: TimeInterval = 0
    }
    private static let lock = NSLock()
    nonisolated(unsafe) private static var replies: [Reply] = []
    nonisolated(unsafe) private static var captured: [URLRequest] = []
    private let callbackLock = NSRecursiveLock()
    private var stopped = false

    static func body(_ temperature: Int = 21) -> Data {
        Data(#"{"current":{"temperature_2m":\#(temperature),"apparent_temperature":20,"weather_code":0},"hourly":{"time":["2026-06-21T04:00","2026-06-21T12:00","2026-06-21T23:00"],"temperature_2m":[10,20,15],"apparent_temperature":[9,19,14],"weather_code":[2,3,1]}}"#.utf8)
    }
    static func reset(_ replies: [Reply] = []) {
        lock.lock(); defer { lock.unlock() }; self.replies = replies; captured = []
    }
    static var requests: [URLRequest] {
        lock.lock(); defer { lock.unlock() }; return captured
    }
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.lock.lock()
        Self.captured.append(request)
        let reply = Self.replies.isEmpty ? Reply() : Self.replies.removeFirst()
        Self.lock.unlock()
        DispatchQueue.global().asyncAfter(deadline: .now() + reply.delay) { [self] in
            callbackLock.lock(); defer { callbackLock.unlock() }
            guard !stopped else { return }
            if let error = reply.error {
                client?.urlProtocol(self, didFailWithError: URLError(error)); return
            }
            client?.urlProtocol(self, didReceive: HTTPURLResponse(url: request.url!, statusCode: reply.status,
                httpVersion: nil, headerFields: ["Content-Type": "application/json"])!, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: reply.data)
            client?.urlProtocolDidFinishLoading(self)
        }
    }
    override func stopLoading() {
        callbackLock.lock(); defer { callbackLock.unlock() }; stopped = true
    }
}

extension CityWeatherProvider {
    func weatherTestCacheCount() -> Int { responseCache.count }
    func weatherTestFlightCount() -> Int { inFlightResponses.count }
    func weatherTestUsesMemoryOnlySession() -> Bool { session.configuration.urlCache == nil }
    func drainWeatherTestRequests() async {
        for task in inFlightResponses.values { _ = try? await task.value }
    }
}

@MainActor private final class WeatherPresentationModel: ObservableObject {
    @Published var presented = false
    @Published var city: City
    @Published var dark = false
    let date = Date()
    init(city: City) { self.city = city }
}

@MainActor private struct WeatherPresentationHost: View {
    @ObservedObject var model: WeatherPresentationModel
    var body: some View {
        Color.clear.sheet(isPresented: $model.presented) {
            CityDetailsView(city: model.city, primaryCity: model.city, date: model.date,
                            relativeOffsetMinutes: 0, cityViewPreference: .basic)
                .environment(\.appTheme, model.dark ? .dark : .light)
                .preferredColorScheme(model.dark ? .dark : .light)
        }
    }
}

@MainActor final class WeatherCacheTests: XCTestCase {
    // Fixtures belong to the caller, as in production: providers never resolve names.
    private var coordinates: [String: LocalCityCoordinates.Coordinate] = [:]
    private func instant(_ text: String) -> Date { ISO8601DateFormatter().date(from: text)! }
    private var selected: Date { instant("2026-06-21T11:00:00Z") }
    private func request(_ id: String = "a", name: String = "London", zone: String = "Europe/London",
                         selected: Date? = nil, requestedAt: Date? = nil) -> WeatherRequest {
        WeatherRequest(cityID: id, cityName: name, timeZoneID: zone, coordinate: coordinates[id],
                       snapshotDate: selected ?? self.selected, requestedAt: requestedAt ?? selected ?? self.selected,
                       isReferenceOffsetCity: false)
    }
    private func provider(_ clock: WeatherTestClock, solar: CitySunEventProvider? = nil) -> CityWeatherProvider {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil
        configuration.protocolClasses = [CachedWeatherProtocol.self]
        return CityWeatherProvider(sunEventProvider: solar ?? CitySunEventProvider(),
            session: URLSession(configuration: configuration), now: { clock.now() })
    }
    private func seed(_ provider: CityWeatherProvider, id: String = "a", latitude: Double = 51.5074,
                      longitude: Double = -0.1278) async {
        coordinates[id] = .init(latitude: latitude, longitude: longitude)
    }
    private func content(_ result: WeatherResolution, file: StaticString = #filePath, line: UInt = #line) throws -> WeatherCardContent {
        guard case .loaded(let value) = result else {
            XCTFail("Expected weather content", file: file, line: line)
            throw URLError(.cannotParseResponse)
        }
        return value
    }
    private func assertError(_ result: WeatherResolution, file: StaticString = #filePath, line: UInt = #line) {
        guard case .error = result else { return XCTFail("Expected unavailable weather", file: file, line: line) }
    }
    private func waitForRequests(_ count: Int) async throws {
        for _ in 0..<200 {
            if CachedWeatherProtocol.requests.count >= count { return }
            try await Task.sleep(for: .milliseconds(10))
        }
        XCTFail("Expected \(count) requests, got \(CachedWeatherProtocol.requests.count)")
    }

    func testSavedCoordinateSnapshotFeedsWeatherAndSolarWithoutNameResolution() async throws {
        CachedWeatherProtocol.reset()
        let solar = CitySunEventProvider(), provider = provider(WeatherTestClock(selected), solar: solar)
        let cities = [City(name: "Springfield", timeZoneID: "America/New_York", canonicalID: "same-id", latitude: 42.1015, longitude: -72.5898),
                      City(name: "Springfield", timeZoneID: "America/New_York", canonicalID: "same-id", latitude: 43.2984, longitude: -72.4823)]
        for city in cities {
            let view = CityDetailsView(city: city, primaryCity: city, date: selected, relativeOffsetMinutes: 0, cityViewPreference: .basic)
            let point = try XCTUnwrap(view.coordinateSnapshot)
            let weather = WeatherRequest(cityID: city.id, cityName: city.name, timeZoneID: city.timeZoneID,
                coordinate: point, snapshotDate: selected, requestedAt: selected, isReferenceOffsetCity: false)
            _ = try content(await provider.resolve(for: weather))
            let solarCount = await solar.weatherTestSolarCacheCount()
            // Instant-based icons do not populate the card's daily solar cache.
            var calendar = Calendar(identifier: .gregorian); calendar.timeZone = city.timeZone
            _ = await solar.sunEvents(for: selected, coordinate: .init(latitude: point.latitude, longitude: point.longitude),
                                      timeZone: city.timeZone, calendar: calendar)
            let after = await solar.weatherTestSolarCacheCount()
            XCTAssertEqual(after, solarCount + 1)
            let query = URLComponents(url: try XCTUnwrap(CachedWeatherProtocol.requests.last?.url), resolvingAgainstBaseURL: false)!.queryItems!
            XCTAssertEqual(query.first { $0.name == "latitude" }?.value, String(point.latitude))
            XCTAssertEqual(query.first { $0.name == "longitude" }?.value, String(point.longitude))
            _ = try content(await provider.resolve(for: weather))
        }
        XCTAssertEqual(CachedWeatherProtocol.requests.count, 2)
        let count = await provider.weatherTestCacheCount(); XCTAssertEqual(count, 2)
    }

    func testFirstFetchFreshHitAndRefreshAtExactlyFifteenMinutes() async throws {
        CachedWeatherProtocol.reset([.init(data: CachedWeatherProtocol.body(21)), .init(data: CachedWeatherProtocol.body(22))])
        let clock = WeatherTestClock(selected), provider = provider(clock)
        await seed(provider)
        var result = try content(await provider.resolve(for: request()))
        XCTAssertEqual(result.value, "21°C"); XCTAssertEqual(CachedWeatherProtocol.requests.count, 1)
        clock.advance(899)
        result = try content(await provider.resolve(for: request()))
        XCTAssertEqual(result.value, "21°C"); XCTAssertEqual(CachedWeatherProtocol.requests.count, 1)
        clock.advance(1)
        result = try content(await provider.resolve(for: request()))
        XCTAssertEqual(result.value, "22°C"); XCTAssertEqual(CachedWeatherProtocol.requests.count, 2)
        let count = await provider.weatherTestCacheCount(); XCTAssertEqual(count, 1)
        let memoryOnly = await CityWeatherProvider(sunEventProvider: CitySunEventProvider()).weatherTestUsesMemoryOnlySession()
        XCTAssertTrue(memoryOnly)
    }

    func testLocationAndTimeZoneSeparateEntriesWhileRenamesReuseThem() async throws {
        CachedWeatherProtocol.reset()
        let provider = provider(WeatherTestClock(selected))
        await seed(provider, id: "a"); await seed(provider, id: "renamed")
        await seed(provider, id: "b", latitude: 42.1015, longitude: -72.5898)
        _ = try content(await provider.resolve(for: request("a", name: "Springfield")))
        _ = try content(await provider.resolve(for: request("b", name: "Springfield")))
        XCTAssertEqual(CachedWeatherProtocol.requests.count, 2)
        _ = try content(await provider.resolve(for: request("renamed", name: "My home")))
        XCTAssertEqual(CachedWeatherProtocol.requests.count, 2)
        _ = try content(await provider.resolve(for: request("a", zone: "America/New_York")))
        XCTAssertEqual(CachedWeatherProtocol.requests.count, 3)
    }

    func testImplicitServiceLocalDateAndClockRollbackInvalidateCache() async throws {
        CachedWeatherProtocol.reset()
        let clock = WeatherTestClock(instant("2026-06-21T22:59:00Z")), provider = provider(clock)
        await seed(provider)
        _ = try content(await provider.resolve(for: request()))
        clock.advance(120) // London crosses midnight; relative forecast dates change.
        _ = try content(await provider.resolve(for: request()))
        XCTAssertEqual(CachedWeatherProtocol.requests.count, 2)
        clock.advance(-1) // A clock adjustment must not extend an entry's lifetime.
        _ = try content(await provider.resolve(for: request()))
        XCTAssertEqual(CachedWeatherProtocol.requests.count, 3)
    }

    func testExpiredResponseIsNotShownWhenRefreshFailsAndFailuresAreNotCached() async throws {
        CachedWeatherProtocol.reset([.init(), .init(error: .notConnectedToInternet), .init(data: CachedWeatherProtocol.body(23))])
        let clock = WeatherTestClock(selected), provider = provider(clock)
        await seed(provider)
        _ = try content(await provider.resolve(for: request()))
        clock.advance(900)
        assertError(await provider.resolve(for: request()))
        let count = await provider.weatherTestCacheCount(); XCTAssertEqual(count, 0)
        let refreshed = try content(await provider.resolve(for: request()))
        XCTAssertEqual(refreshed.value, "23°C"); XCTAssertEqual(CachedWeatherProtocol.requests.count, 3)
    }

    func testMalformedHTTPAndDecodedPayloadsNeverBecomeCacheEntries() async throws {
        let invalid = [
            CachedWeatherProtocol.Reply(status: 500),
            .init(data: Data("not JSON".utf8)), .init(data: Data("{}".utf8)),
            .init(data: Data(#"{"current":{"temperature_2m":1e100,"apparent_temperature":20,"weather_code":0}}"#.utf8)),
            .init(data: Data(#"{"hourly":{"time":["2026-06-21T12:00"],"temperature_2m":[],"apparent_temperature":[20],"weather_code":[0]}}"#.utf8)),
            .init(data: Data(#"{"hourly":{"time":["invalid"],"temperature_2m":[21],"apparent_temperature":[20],"weather_code":[0]}}"#.utf8))
        ]
        for reply in invalid {
            CachedWeatherProtocol.reset([reply, .init()])
            let provider = provider(WeatherTestClock(selected)); await seed(provider)
            assertError(await provider.resolve(for: request()))
            let count = await provider.weatherTestCacheCount(); XCTAssertEqual(count, 0)
            _ = try content(await provider.resolve(for: request()))
            XCTAssertEqual(CachedWeatherProtocol.requests.count, 2)
        }
    }

    func testSimultaneousRequestsShareOneFetchAndSelectTheirOwnTimeAndIcon() async throws {
        CachedWeatherProtocol.reset([.init(delay: 0.15)])
        let provider = provider(WeatherTestClock(selected)); await seed(provider)
        let requests = [request(selected: instant("2026-06-21T03:00:00Z"), requestedAt: selected),
                        request(), request(selected: instant("2026-06-21T22:00:00Z"), requestedAt: selected)]
        let tasks = requests.map { request in Task { await provider.resolve(for: request) } }
        let early = try content(await tasks[0].value)
        let current = try content(await tasks[1].value)
        let late = try content(await tasks[2].value)
        XCTAssertEqual(early.value, "10°C"); XCTAssertEqual(early.symbolName, "cloud.moon.fill")
        XCTAssertEqual(current.value, "21°C"); XCTAssertEqual(current.symbolName, "sun.max.fill")
        XCTAssertEqual(late.value, "15°C"); XCTAssertEqual(late.symbolName, "cloud.moon.fill")
        XCTAssertEqual(CachedWeatherProtocol.requests.count, 1)
        let count = await provider.weatherTestFlightCount(); XCTAssertEqual(count, 0)
    }

    func testFreshCacheHitReclassifiesPolarSunsetAtSelectedInstant() async throws {
        CachedWeatherProtocol.reset()
        let before = instant("2026-08-25T21:54:00Z")
        let after = instant("2026-08-25T21:58:00Z")
        let provider = provider(WeatherTestClock(before))
        await seed(provider, latitude: 78.22334, longitude: 15.64689)
        let day = try content(await provider.resolve(for: request(name: "Longyearbyen",
            zone: "Arctic/Longyearbyen", selected: before)))
        let night = try content(await provider.resolve(for: request(name: "Renamed city",
            zone: "Arctic/Longyearbyen", selected: after)))
        XCTAssertEqual(day.symbolName, "sun.max.fill")
        XCTAssertEqual(night.symbolName, "moon.stars.fill")
        XCTAssertEqual(day.value, night.value)
        XCTAssertEqual(CachedWeatherProtocol.requests.count, 1)
    }

    func testDSTGapTimestampDoesNotRejectOtherUsableHours() async throws {
        let data = Data(#"{"hourly":{"time":["2026-03-29T00:00","2026-03-29T01:00","2026-03-29T02:00"],"temperature_2m":[10,11,12],"apparent_temperature":[9,10,11],"weather_code":[0,0,0]}}"#.utf8)
        CachedWeatherProtocol.reset([.init(data: data)])
        let date = instant("2026-03-29T01:00:00Z") // 02:00 BST; 01:00 local never occurs.
        let provider = provider(WeatherTestClock(date)); await seed(provider)
        let selected = request(selected: date, requestedAt: date.addingTimeInterval(600))
        let first = try content(await provider.resolve(for: selected))
        let cached = try content(await provider.resolve(for: selected))
        XCTAssertEqual(first.value, "12°C"); XCTAssertEqual(cached.value, first.value)
        XCTAssertEqual(CachedWeatherProtocol.requests.count, 1)
    }

    func testCancellingOneWaiterDoesNotCancelAnotherOrPublishOldSameCityData() async throws {
        CachedWeatherProtocol.reset([.init(delay: 0.15)])
        let provider = provider(WeatherTestClock(selected)); await seed(provider)
        let old = Task { await provider.resolve(for: request(selected: instant("2026-06-21T03:00:00Z"), requestedAt: selected)) }
        try await waitForRequests(1)
        let latest = Task { await provider.resolve(for: request()) }
        old.cancel()
        let value = try content(await latest.value); XCTAssertEqual(value.value, "21°C")
        assertError(await old.value)
        XCTAssertEqual(CachedWeatherProtocol.requests.count, 1)
    }

    func testOlderCityResponseFinishingLastCannotReplaceNewCityCache() async throws {
        CachedWeatherProtocol.reset([.init(data: CachedWeatherProtocol.body(11), delay: 0.2),
                                     .init(data: CachedWeatherProtocol.body(22))])
        let provider = provider(WeatherTestClock(selected)); await seed(provider)
        await seed(provider, id: "b", latitude: 13.7563, longitude: 100.5018)
        let old = Task { await provider.resolve(for: request()) }
        try await waitForRequests(1)
        let newer = try content(await provider.resolve(for: request("b")))
        XCTAssertEqual(newer.value, "22°C")
        let oldValue = try content(await old.value)
        let cachedNewValue = try content(await provider.resolve(for: request("b")))
        XCTAssertEqual(oldValue.value, "11°C")
        XCTAssertEqual(cachedNewValue.value, "22°C")
        XCTAssertEqual(CachedWeatherProtocol.requests.count, 2)
    }

    func testDismissalThenReopeningJoinsExistingFetchAndCancelledCacheHitDoesNotPublish() async throws {
        CachedWeatherProtocol.reset([.init(delay: 0.15)])
        let provider = provider(WeatherTestClock(selected)); await seed(provider)
        let dismissed = Task { await provider.resolve(for: request()) }
        try await waitForRequests(1); dismissed.cancel()
        _ = try content(await provider.resolve(for: request()))
        assertError(await dismissed.value)
        let cancelledHit = Task { await provider.resolve(for: request()) }
        cancelledHit.cancel()
        assertError(await cancelledHit.value)
        _ = try content(await provider.resolve(for: request()))
        XCTAssertEqual(CachedWeatherProtocol.requests.count, 1)
    }

    func testLeastRecentlyUsedCapacityIsBoundedAtSixteenResponses() async throws {
        CachedWeatherProtocol.reset()
        let provider = provider(WeatherTestClock(selected))
        for index in 0...16 { await seed(provider, id: "\(index)", latitude: Double(index), longitude: 10) }
        for index in 0..<16 { _ = try content(await provider.resolve(for: request("\(index)"))) }
        _ = try content(await provider.resolve(for: request("0"))) // Keep the oldest insertion recently used.
        _ = try content(await provider.resolve(for: request("16")))
        _ = try content(await provider.resolve(for: request("0")))
        XCTAssertEqual(CachedWeatherProtocol.requests.count, 17)
        _ = try content(await provider.resolve(for: request("1"))) // Least recently used was evicted.
        XCTAssertEqual(CachedWeatherProtocol.requests.count, 18)
        let count = await provider.weatherTestCacheCount(); XCTAssertEqual(count, 16)
    }

    func testActualSheetCitySwitchDismissReopenThemesAndHourFormats() async throws {
        CachedWeatherProtocol.reset([.init(data: CachedWeatherProtocol.body(11), delay: 0.4),
                                     .init(data: CachedWeatherProtocol.body(22)),
                                     .init(data: CachedWeatherProtocol.body(33), delay: 0.4)])
        let savedProvider = CityDetailsView.weatherProvider
        CityDetailsView.weatherProvider = provider(WeatherTestClock(Date()), solar: CityDetailsView.sunEventProvider)
        defer { CityDetailsView.weatherProvider = savedProvider }
        let key = AppTimeFormatPreference.storageKey, saved = UserDefaults.standard.object(forKey: AppTimeFormatPreference.storageKey)
        defer { UserDefaults.standard.set(saved, forKey: key) }
        let cities = [City(name: "Cache Alpha", timeZoneID: "Europe/London", canonicalID: "cache-ui-a", latitude: 51.5074, longitude: -0.1278),
                      City(name: "Cache Beta", timeZoneID: "Asia/Bangkok", canonicalID: "cache-ui-b", latitude: 13.7563, longitude: 100.5018),
                      City(name: "Cache Gamma", timeZoneID: "Asia/Tokyo", canonicalID: "cache-ui-c", latitude: 35.6762, longitude: 139.6503)]
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let model = WeatherPresentationModel(city: cities[0])
        let window = UIWindow(windowScene: scene)
        window.rootViewController = UIHostingController(rootView: WeatherPresentationHost(model: model))
        window.makeKeyAndVisible()
        defer { window.isHidden = true; previous?.makeKeyAndVisible() }
        model.presented = true
        try await waitForRequests(1)
        model.city = cities[1]
        try await waitForRequests(2)
        try await Task.sleep(for: .milliseconds(800))
        try assertVisibleWeather("22", in: window) // Alpha finishes last, but Beta stays visible.
        model.presented = false
        try await Task.sleep(for: .milliseconds(600))
        XCTAssertNil(window.rootViewController?.presentedViewController)
        model.presented = true
        try await Task.sleep(for: .milliseconds(600))
        try assertVisibleWeather("22", in: window)
        XCTAssertEqual(CachedWeatherProtocol.requests.count, 2)
        for dark in [true, false] {
            for preference in [AppTimeFormatPreference.twelveHour, .twentyFourHour] {
                model.dark = dark; UserDefaults.standard.set(preference.rawValue, forKey: key)
                try await Task.sleep(for: .milliseconds(150))
                try assertVisibleWeather("22", in: window)
                XCTAssertEqual(CachedWeatherProtocol.requests.count, 2)
            }
        }
        model.city = cities[2]
        try await waitForRequests(3)
        model.presented = false
        await CityDetailsView.weatherProvider.drainWeatherTestRequests()
        try await Task.sleep(for: .milliseconds(600))
        XCTAssertNil(window.rootViewController?.presentedViewController)
        model.presented = true
        try await Task.sleep(for: .milliseconds(600))
        try assertVisibleWeather("33", in: window)
        XCTAssertEqual(CachedWeatherProtocol.requests.count, 3)
        model.presented = false
        try await Task.sleep(for: .milliseconds(400))
    }

    private func assertVisibleWeather(_ temperature: String, in window: UIWindow) throws {
        let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        let request = VNRecognizeTextRequest(); request.recognitionLevel = .accurate
        try VNImageRequestHandler(cgImage: XCTUnwrap(image.cgImage)).perform([request])
        let text = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
        XCTAssertTrue(text.contains("\(temperature)°C") || text.contains("\(temperature) °C"), text)
        let attachment = XCTAttachment(image: image); attachment.name = "weather-cache-\(temperature)"
        attachment.lifetime = .keepAlways; add(attachment)
    }
}
