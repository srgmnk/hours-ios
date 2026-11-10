import Foundation

/// Decorative geography only. Never changes a City or participates in search identity.
struct NightCityLights {
    enum Style {
        // Measured properties of the bundled Figma sprite. Appearance edits must
        // update that export too; these values document its geometry and colors.
        static let diameter: Float = 2 // core, screen points; independent of map scale
        static let glowDiameter: Float = 6
        static let blurRadius: Float = 4
        static let glowOpacity: Float = 0.6
        static let spriteDiameter: Float = 14 // exported glow bounds, including blur
        static let invisibleElevation = -3.0
        static let fullElevation = -9.0
        static let brightness: Float = 1
        static let color = SIMD3<Float>(1, 0.9342057108879089, 0.7368227243423462)
        static let glowColor = SIMD3<Float>(1, 0.75, 0)
    }

    struct Light: Equatable {
        let id: String
        let coordinate: LocalCityCoordinates.Coordinate
        let position: SIMD2<Float>

        init(id: String, coordinate: LocalCityCoordinates.Coordinate) {
            self.id = id
            self.coordinate = coordinate
            let latitude = min(85.05112878, max(-85.05112878, coordinate.latitude)) * .pi / 180
            position = SIMD2(Float(SolarPosition.wrap((coordinate.longitude + 180) / 360, period: 1)),
                             Float(min(1, max(0, (1 - asinh(tan(latitude)) / .pi) / 2))))
        }
    }

    private let catalog: [Light]
    private let catalogIdentities: Set<String>
    private let resolver: LegacyCityCoordinateResolver

    init(bundle: Bundle = .main) {
        let url = bundle.url(forResource: "cities", withExtension: "json", subdirectory: "Resources")
            ?? bundle.url(forResource: "cities", withExtension: "json")
        let items = url.flatMap { try? Data(contentsOf: $0) }
            .flatMap { try? JSONDecoder().decode([CitySearchItem].self, from: $0) } ?? []
        self.init(catalog: items)
    }

    init(catalog items: [CitySearchItem]) {
        // Only the curated base changes; every other saved city uses the dynamic path.
        let decorativeIDs = Set(DecorativeCityIDs.catalogIDs)
        catalog = DecorativeCityIDs.catalogIDs.map {
            Light(id: "catalog:" + $0, coordinate: LocalCityCoordinates.byCatalogID[$0]!)
        }
        let identities = Dictionary(grouping: items.filter { decorativeIDs.contains($0.id) }, by: \.canonicalIdentity)
        catalogIdentities = Set(identities.compactMap { id, entries in
            entries.count == 1 && LocalCityCoordinates.byCatalogID[entries[0].id] != nil ? id : nil
        })
        resolver = LegacyCityCoordinateResolver(catalog: items)
    }

    func lights(savedCities: [City]) -> [Light] {
        var result = catalog
        var seen = catalogIdentities
        for city in savedCities {
            guard !seen.contains(city.id), let coordinate = resolver.coordinate(for: city) else { continue }
            seen.insert(city.id)
            result.append(Light(id: "saved:" + city.id, coordinate: coordinate))
        }
        return result
    }

    static func visibility(elevation: Double) -> Float {
        let t = min(1, max(0, (Style.invisibleElevation - elevation) / (Style.invisibleElevation - Style.fullElevation)))
        return Float(t * t * (3 - 2 * t))
    }
}
