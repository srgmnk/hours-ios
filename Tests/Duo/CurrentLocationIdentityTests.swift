import XCTest
import CoreLocation
@testable import MapHarness

@MainActor final class CurrentLocationIdentityTests: XCTestCase {
    private let london = CitySearchItem(id: "london-gb", city: "London", country: "United Kingdom",
        timeZoneIdentifier: "Europe/London", aliases: [])
    private let manchester = CitySearchItem(id: "manchester-gb", city: "Manchester", country: "United Kingdom",
        timeZoneIdentifier: "Europe/London", aliases: [])
    private let bangkok = CitySearchItem(id: "bangkok-th", city: "Bangkok", country: "Thailand",
        timeZoneIdentifier: "Asia/Bangkok", aliases: [])

    private func check(_ cities: [City], location: CitySearchItem?, expected: String?,
                       file: StaticString = #filePath, line: UInt = #line) throws {
        // Exercise the production matcher with both Primary orders and persisted models.
        let resolver = LegacyCityCoordinateResolver()
        for order in [cities, Array(cities.reversed())] {
            let reloaded = try JSONDecoder().decode([City].self, from: JSONEncoder().encode(order))
            XCTAssertEqual(reloaded, order, file: file, line: line)
            let controller = CityListReorderViewController()
            controller.citiesLocal = reloaded
            controller.userCurrentLocationItem = location
            let index = controller.currentLocationMatchIndex()
            XCTAssertEqual(index.map { controller.citiesLocal[$0].id }, expected, file: file, line: line)
            XCTAssertEqual(controller.citiesLocal, order, file: file, line: line)
            XCTAssertEqual(controller.citiesLocal.primaryCity?.id, order.first?.id, file: file, line: line)
            for (before, after) in zip(order, controller.citiesLocal) {
                XCTAssertEqual(resolver.coordinate(for: before), resolver.coordinate(for: after), file: file, line: line)
            }
        }
    }

    func testLondonAbsentNeverBadgesManchesterOrAnotherSharedZoneCity() throws {
        try check([manchester.asCity], location: london, expected: nil)
        try check([manchester.asCity, bangkok.asCity], location: london, expected: nil)
        let oxford = CitySearchItem(id: "oxford-gb", city: "Oxford", country: "United Kingdom",
            timeZoneIdentifier: "Europe/London", aliases: [])
        try check([manchester.asCity, oxford.asCity], location: london, expected: nil)
    }

    func testLondonPresentRetainsBadgeThroughRenameReorderAndReload() throws {
        var saved = london.asCity
        saved.customDisplayName = "Home"
        try check([manchester.asCity, saved, bangkok.asCity], location: london, expected: saved.id)
    }

    func testSameNameInDifferentCountriesOrDistinctIdentitiesDoesNotMatch() throws {
        let canadianLondon = CitySearchItem(id: "london-ca", city: "London", country: "Canada",
            timeZoneIdentifier: "America/Toronto", aliases: [])
        try check([canadianLondon.asCity], location: london, expected: nil)
        // Same-name settlements can also share a time zone across country borders.
        let first = CitySearchItem(id: "border-a", city: "San Jose", country: "Colombia",
            timeZoneIdentifier: "America/Bogota", aliases: [], canonicalID: "city:border-a")
        let second = CitySearchItem(id: "border-b", city: "San Jose", country: "Ecuador",
            timeZoneIdentifier: "America/Bogota", aliases: [], canonicalID: "city:border-b")
        try check([second.asCity], location: first, expected: nil)
        let distinctLondon = City(name: "London", timeZoneID: "Europe/London", canonicalID: "city:distinct-london")
        try check([distinctLondon], location: london, expected: nil)
    }

    func testCatalogAndNoncatalogProviderPathsRetainIdentityAndMapCoordinates() throws {
        let coordinate = CLLocationCoordinate2D(latitude: 13.7449, longitude: 100.5332)
        let catalog = try XCTUnwrap(CitySearchProvider.shared.canonicalItemForCurrentLocation(
            city: "London", country: "United Kingdom", timeZoneIdentifier: "Europe/London"))
        let located = CurrentLocationCityProvider.cityItem(city: "London", country: "United Kingdom",
            timeZoneIdentifier: "Europe/London", resolvedCoordinate: coordinate, deviceCoordinate: coordinate)
        XCTAssertEqual(located.canonicalIdentity, catalog.canonicalIdentity)
        try check([manchester.asCity, catalog.asCity], location: located, expected: catalog.canonicalIdentity)
        let noncatalog = CurrentLocationCityProvider.cityItem(city: "Pathum Wan District", country: "Thailand",
            timeZoneIdentifier: "Asia/Bangkok", resolvedCoordinate: coordinate, deviceCoordinate: coordinate)
        XCTAssertNil(CitySearchProvider.shared.canonicalItemForCurrentLocation(
            city: noncatalog.city, country: noncatalog.country, timeZoneIdentifier: noncatalog.timeZoneIdentifier))
        XCTAssertEqual(noncatalog.asCity.latitude, coordinate.latitude)
        XCTAssertEqual(noncatalog.asCity.longitude, coordinate.longitude)
        try check([bangkok.asCity, noncatalog.asCity], location: noncatalog, expected: noncatalog.canonicalIdentity)
        try check([bangkok.asCity], location: noncatalog, expected: nil)
    }

    func testUnavailableLocationAndUnverifiedLegacyIdentityStayUnbadged() throws {
        try check([london.asCity, manchester.asCity], location: nil, expected: nil)
        let unresolved = CitySearchItem(id: "unresolved", city: "", country: "",
            timeZoneIdentifier: "Europe/London", aliases: [])
        try check([manchester.asCity], location: unresolved, expected: nil)
        let legacy = City(name: "London", timeZoneID: "Europe/London")
        try check([legacy], location: london, expected: nil)
        // Missing coordinates do not invalidate an established canonical identity.
        let known = City(name: "London", timeZoneID: "Europe/London", canonicalID: london.canonicalIdentity)
        try check([known], location: london, expected: known.id)
    }
}
