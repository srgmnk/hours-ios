import XCTest
import CoreLocation
import SwiftUI
@testable import MapHarness

@MainActor final class CityDetailsGeographyTests: XCTestCase {
    private let instant = ISO8601DateFormatter().date(from: "2026-06-21T10:00:00Z")!
    private func details(_ city: City, primary: City? = nil) -> CityDetailsView {
        CityDetailsView(city: city, primaryCity: primary ?? city, date: instant,
                        relativeOffsetMinutes: 0, cityViewPreference: .basic)
    }
    private func catalog() throws -> [CitySearchItem] {
        let url = Bundle.main.url(forResource: "cities", withExtension: "json", subdirectory: "Resources")
            ?? Bundle.main.url(forResource: "cities", withExtension: "json")
        return try JSONDecoder().decode([CitySearchItem].self, from: Data(contentsOf: XCTUnwrap(url)))
    }
    private func sunRequest(_ city: City) -> SunRequest {
        SunRequest(cityID: city.id, cityName: city.name, timeZoneID: city.timeZoneID,
                   coordinate: details(city).coordinateSnapshot, timeZone: city.timeZone,
                   snapshotDate: instant, requestedAt: instant, isReferenceOffsetCity: false)
    }

    func testEveryCatalogIdentityRecoversExactIndependentPointAndOverridesStoredPoint() throws {
        let entries = try catalog().filter { LocalCityCoordinates.byCatalogID[$0.id] != nil }
        XCTAssertEqual(entries.count, 3000)
        for item in entries {
            let expected = LocalCityCoordinates.byCatalogID[item.id]
            let legacy = City(canonicalCity: item.asCity.canonicalCity)
            let alternatePoint = City(canonicalCity: legacy.canonicalCity, latitude: 0, longitude: 0)
            XCTAssertEqual(details(legacy).coordinateSnapshot, expected, item.id)
            XCTAssertEqual(details(alternatePoint).coordinateSnapshot, expected, item.id)
        }
    }

    func testAmbiguousCatalogIdentityAndNameZoneGuessAreNotRecoveryEvidence() throws {
        let london = try XCTUnwrap(try catalog().first { $0.id == "london-gb" })
        let ambiguous = LegacyCityCoordinateResolver(catalog: [london, london])
        XCTAssertNil(ambiguous.catalogCoordinate(for: City(canonicalCity: london.asCity.canonicalCity)))
        for id in ["legacy", "london-gb", "city:london|country:_|tz:europe-london"] {
            let city = City(name: "London", timeZoneID: "Europe/London", canonicalID: id)
            XCTAssertNil(details(city).coordinateSnapshot)
        }
    }

    func testRemoteSelectionsKeepSameNameSettlementsDistinctThroughJSONAndRename() throws {
        // Same name/country/zone is deliberately insufficient; selection evidence
        // carries distinct place IDs and points through the existing search merger.
        func item(_ id: String, _ country: String, _ latitude: Double, _ longitude: Double) -> CitySearchItem {
            CitySearchItem(id: id, city: "Springfield", country: country,
                timeZoneIdentifier: "America/New_York", aliases: [], geographicalEvidence: .init(
                    placeIdentifier: id, alternatePlaceIdentifiers: nil, originalName: "Springfield",
                    cityName: "Springfield", countryCode: country, coordinates: .init(latitude: latitude, longitude: longitude),
                    cityWithContext: nil, cityWithFullContext: nil, fullAddress: nil, shortAddress: nil,
                    pointOfInterestCategory: nil))
        }
        let items = [item("us-ma", "US", 42.1015, -72.5898), item("us-vt", "US", 43.2984, -72.4823),
                     item("ca", "CA", 45.42, -75.7)]
        let selected = CitySearchDeduplicator.merge(local: [], remote: items, catalog: []).map(\.asCity)
        XCTAssertEqual(Set(selected.map(\.id)).count, 3)
        let restored = try JSONDecoder().decode([City].self, from: JSONEncoder().encode(selected))
        for (index, var city) in restored.enumerated() {
            let before = details(city).coordinateSnapshot
            XCTAssertEqual(before?.latitude, items[index].geographicalEvidence?.coordinates?.latitude)
            XCTAssertEqual(before?.longitude, items[index].geographicalEvidence?.coordinates?.longitude)
            city.customDisplayName = "Home"
            XCTAssertEqual(details(city).coordinateSnapshot, before)
            XCTAssertEqual(details(city).cardResolutionTaskID, details(restored[index]).cardResolutionTaskID)
        }
        for city in restored.reversed() {
            XCTAssertEqual(details(city, primary: restored.last).coordinateSnapshot, details(city).coordinateSnapshot)
        }
    }

    func testCurrentLocationPointSurvivesPrimaryChangeWithoutTransferringLocation() throws {
        let device = CLLocationCoordinate2D(latitude: 18.865, longitude: 99.35)
        let settlement = CLLocationCoordinate2D(latitude: 18.866, longitude: 99.351)
        for resolved in [settlement, CLLocationCoordinate2D(latitude: .nan, longitude: .nan)] {
            let location = CurrentLocationCityProvider.cityItem(city: "Small location fixture", country: "Thailand",
                timeZoneIdentifier: "Asia/Bangkok", resolvedCoordinate: resolved, deviceCoordinate: device).asCity
            let expected = resolved.latitude.isFinite ? settlement : device
            let restored = try JSONDecoder().decode(City.self, from: JSONEncoder().encode(location))
            let other = City(name: "Other", timeZoneID: "Asia/Bangkok", canonicalID: "other", latitude: 10, longitude: 101)
            XCTAssertEqual(details(restored, primary: other).coordinateSnapshot?.latitude, expected.latitude)
            XCTAssertEqual(details(restored, primary: other).coordinateSnapshot?.longitude, expected.longitude)
            XCTAssertEqual(details(other, primary: restored).coordinateSnapshot?.latitude, 10)
        }
    }

    func testMissingInvalidAndReferenceGeographyStayUnavailableWithoutNetwork() async {
        let solar = CitySunEventProvider(), weather = CityWeatherProvider(sunEventProvider: CitySunEventProvider())
        for latitude in [Double.nan, .infinity, 91] {
            let city = City(name: "London", timeZoneID: "Europe/London", canonicalID: "unresolved",
                            latitude: latitude, longitude: 0)
            XCTAssertNil(details(city).coordinateSnapshot)
            guard case .error = await solar.resolve(for: sunRequest(city)) else { return XCTFail("Unknown solar location") }
            let request = WeatherRequest(cityID: city.id, cityName: city.name, timeZoneID: city.timeZoneID,
                coordinate: details(city).coordinateSnapshot, snapshotDate: instant, requestedAt: instant,
                isReferenceOffsetCity: false)
            guard case .error = await weather.resolve(for: request) else { return XCTFail("Unknown weather location") }
        }
        let count = await weather.weatherTestCacheCount()
        XCTAssertEqual(count, 0)
        let reference = City(name: "UTC", timeZoneID: "UTC", canonicalID: "custom.utc")
        XCTAssertNil(details(reference).coordinateSnapshot)
    }

    func testCoordinateOnlyReplacementRestartsDetailsAndSeparatesSolarCache() async throws {
        let first = City(name: "Same", timeZoneID: "Europe/London", canonicalID: "same", latitude: 51.5, longitude: -0.12)
        let second = City(name: "Same", timeZoneID: "Europe/London", canonicalID: "same", latitude: 58.9, longitude: -3.3)
        XCTAssertNotEqual(details(first).cardResolutionTaskID, details(second).cardResolutionTaskID)
        let solar = CitySunEventProvider()
        var events: [Date] = []
        for city in [first, second, first] {
            guard case .loaded(let value) = await solar.resolve(for: sunRequest(city)) else { return XCTFail("Expected solar events") }
            events.append(value.primaryDate)
        }
        XCTAssertEqual(events[0], events[2])
        XCTAssertGreaterThan(abs(events[0].timeIntervalSince(events[1])), 30 * 60)
        let count = await solar.weatherTestSolarCacheCount()
        XCTAssertEqual(count, 4) // Today + tomorrow at each distinct coordinate.
    }
}
