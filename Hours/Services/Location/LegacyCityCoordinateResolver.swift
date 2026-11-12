import Foundation

/// Read-only geography for saved cities. Never infers identity from display text.
struct LegacyCityCoordinateResolver {
    typealias Coordinate = LocalCityCoordinates.Coordinate

    private let coordinatesByCanonicalID: [String: Coordinate]

    init(bundle: Bundle = .main) {
        let urls = [
            bundle.url(forResource: "cities", withExtension: "json", subdirectory: "Resources"),
            bundle.url(forResource: "cities", withExtension: "json")
        ]
        for case let url? in urls {
            if let data = try? Data(contentsOf: url),
               let catalog = try? JSONDecoder().decode([CitySearchItem].self, from: data),
               !catalog.isEmpty {
                self.init(catalog: catalog)
                return
            }
        }
        // An unavailable catalog provides no identity evidence.
        self.init(catalog: [])
    }

    init(catalog: [CitySearchItem]) {
        let groups = Dictionary(grouping: catalog, by: \.canonicalIdentity)
        coordinatesByCanonicalID = groups.reduce(into: [:]) { result, entry in
            // A duplicate identity is ambiguity, even if only one entry has geography.
            guard entry.value.count == 1,
                  let item = entry.value.first,
                  let coordinate = LocalCityCoordinates.byCatalogID[item.id] else { return }
            result[entry.key] = coordinate
        }
    }

    func coordinate(for city: City) -> Coordinate? {
        if let latitude = city.latitude, let longitude = city.longitude,
           latitude.isFinite, longitude.isFinite,
           (-90...90).contains(latitude), (-180...180).contains(longitude) {
            return Coordinate(latitude: latitude, longitude: longitude)
        }
        // Use the existing canonical identity verbatim. Search aliases do not create
        // alternate saved IDs; names, time zones, and raw catalog IDs are not matched.
        return catalogCoordinate(for: city)
    }

    /// Exact, unambiguous catalog identity only; never matches names or time zones.
    func catalogCoordinate(for city: City) -> Coordinate? {
        coordinatesByCanonicalID[city.id]
    }
}
