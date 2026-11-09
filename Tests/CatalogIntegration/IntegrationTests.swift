import Foundation

@main struct CatalogIntegrationTests {
    static var checks = 0
    static func check(_ value: Bool, _ label: String) {
        precondition(value, label)
        checks += 1
    }
    static func wait(_ condition: () -> Bool) async {
        let deadline = Date().addingTimeInterval(5)
        while !condition() {
            precondition(Date() < deadline, "Catalog integration callback timed out")
            await Task.yield()
        }
    }
    static func fixture<T: Decodable>(_ name: String, as type: T.Type) throws -> T {
        let url = Bundle.main.url(forResource: name, withExtension: "json")!
        return try JSONDecoder().decode(T.self, from: Data(contentsOf: url))
    }
    struct FrozenLight: Decodable { let id: String; let catalog_id: String; let canonical_id: String; let latitude: Double; let longitude: Double }
    struct FrozenPosition: Decodable { let id: String; let projected_x_float: Double; let projected_y_float: Double }

    static func main() async throws {
        // Run the pre-existing geographic identity, row stability, ordering and cancellation suite unchanged in intent.
        try await RegressionTests.main()
        let catalog = try fixture("cities", as: [CitySearchItem].self)
        let original = try fixture("original-cities", as: [CitySearchItem].self)
        let lights = try fixture("original-night-lights", as: [FrozenLight].self)
        let positions = try fixture("original-night-light-positions", as: [FrozenPosition].self)
        let provider = CitySearchProvider.shared
        let originalBundle = Bundle(path: Bundle.main.bundleURL.appendingPathComponent("original-catalog.bundle").path)!
        let old = CitySearchProvider(bundle: originalBundle)
        func item(_ id: String) -> CitySearchItem { catalog.first { $0.id == id }! }
        let samara = item("geonames-499099"), qingyuan = item("geonames-1797945")
        let springIL = item("geonames-4250542"), springMO = item("geonames-4409896")
        let cambridgeGB = item("geonames-2653941"), cambridgeUS = item("geonames-4931972")
        let london = item("london-gb")

        check(catalog.count == 3000 && original.count == 152, "Expanded and frozen catalog counts")
        check(Array(catalog.prefix(152)) == original, "Original 152 objects and order unchanged")
        check(Set(catalog.map(\.id)).count == catalog.count, "Catalog IDs unique")
        check(Set(catalog.map(\.canonicalIdentity)).count == catalog.count, "Persistent canonical IDs unique")
        check(catalog.dropFirst(152).allSatisfy { $0.canonicalID?.hasPrefix("city:geonames:") == true }, "Additions have explicit geographic canonical IDs")
        check(Set(OriginalDecorativeCityIDs.catalogIDs) == Set(original.map(\.id)), "Frozen key scope is exactly the original catalog")
        check(LocalCityCoordinates.byCatalogID.count == 3000 && Set(LocalCityCoordinates.byCatalogID.keys) == Set(catalog.map(\.id)), "Every catalog entry has one keyed coordinate")
        check(lights.allSatisfy { LocalCityCoordinates.byCatalogID[$0.catalog_id] == .init(latitude: $0.latitude, longitude: $0.longitude) }, "Original reviewed coordinate values unchanged")
        check(LocalCityCoordinates.byCatalogID.values.allSatisfy { $0.latitude.isFinite && $0.longitude.isFinite && (-90...90).contains($0.latitude) && (-180...180).contains($0.longitude) }, "All coordinates finite and inside WGS84 ranges")
        check(catalog.allSatisfy { TimeZone(identifier: $0.timeZoneIdentifier) != nil }, "Current host Foundation accepts all zone identifiers")
        for record in catalog.dropFirst(152) {
            let normalized = record.aliases.map(CitySearchProvider.normalize)
            check(normalized.count <= 8 && !normalized.contains("") && Set(normalized).count == normalized.count && !normalized.contains(CitySearchProvider.normalize(record.city)), "Imported aliases normalized unique and bounded: \(record.id)")
        }
        let saved = catalog.map(\.asCity)
        check(try JSONDecoder().decode([City].self, from: JSONEncoder().encode(saved)) == saved, "Saved model round-trip retains IDs, zones and coordinates")
        check(catalog.allSatisfy { record in
            let city = record.asCity, coordinate = LocalCityCoordinates.byCatalogID[record.id]!
            return city.id == record.canonicalIdentity && city.name == record.city && city.timeZoneID == record.timeZoneIdentifier && city.latitude == coordinate.latitude && city.longitude == coordinate.longitude
        }, "Local selections carry the matching registry coordinate into the saved model")
        let resolver = LegacyCityCoordinateResolver(catalog: catalog)
        check(catalog.allSatisfy { record in
            let noCoordinates = City(canonicalCity: .init(id: record.canonicalIdentity, name: record.city, timeZoneID: record.timeZoneIdentifier))
            return resolver.coordinate(for: noCoordinates) == LocalCityCoordinates.byCatalogID[record.id]
        }, "Exact modern catalog IDs recover marker coordinates when old saves lack coordinates")
        let modernRemote = City(canonicalCity: .init(id: "city:mapkit:integration-fixture", name: "Samara", timeZoneID: "Europe/Samara"), latitude: 53.2, longitude: 50.1)
        let misleadingRemote = City(canonicalCity: .init(id: "city:mapkit:without-coordinates", name: "Samara", timeZoneID: "Europe/Samara"))
        check(resolver.coordinate(for: modernRemote) == .init(latitude: 53.2, longitude: 50.1), "Persisted remote marker coordinate is used verbatim")
        check(resolver.coordinate(for: misleadingRemote) == nil, "A remote identity without coordinates is never guessed equivalent by name")
        let point = WorldMapProjection.normalizedPoint(resolver.coordinate(for: samara.asCity)!)
        check(point.x.isFinite && point.y.isFinite && (0...1).contains(point.x) && (0...1).contains(point.y), "Imported saved model reaches valid actual marker projection")

        for query in ["Ja", "Jac", "Jack", "London", "Moscow", "Samara", "Самара", "Qingyuan", "清远", "New York", "Tokyo", "Bangkok", "Springfield", "Cambridge"] {
            let results = provider.localResults(matching: query, excluding: [])
            check(results == provider.localResults(matching: query, excluding: []), "Deterministic local results: \(query)")
            check(results.count <= 40 && Set(results.map(\.canonicalIdentity)).count == results.count, "Bounded distinct results: \(query)")
            check(CitySearchDeduplicator.merge(local: results, remote: [], catalog: catalog) == results, "Conservative local merge preserves order and identity: \(query)")
        }
        check(provider.localResults(matching: "Samara", excluding: []).first?.id == samara.id, "English Samara exact city precedes broad matches")
        check(provider.localResults(matching: "Самара", excluding: []).map(\.id) == [samara.id], "Russian Samara alias resolves to the Russian local entity")
        check(provider.localResults(matching: "Qingyuan", excluding: []).first?.id == qingyuan.id, "Qingyuan resolves to Guangdong")
        check(provider.localResults(matching: "清远", excluding: []).map(\.id) == [qingyuan.id], "Chinese Qingyuan alias resolves to Guangdong")
        let springs = provider.localResults(matching: "Springfield", excluding: [])
        check(Set(springs.map(\.id)) == Set([springIL.id, springMO.id]) && springIL.canonicalIdentity != springMO.canonicalIdentity, "Same-country same-zone Springfields remain independently selectable")
        let cambridges = provider.localResults(matching: "Cambridge", excluding: [])
        check(Set(cambridges.map(\.id)) == Set([cambridgeGB.id, cambridgeUS.id]), "Cambridge countries remain distinct")
        check(provider.shouldFetchFallback(for: "Samara", localResultCount: provider.localResults(matching: "Samara", excluding: []).count), "Small city-match sets retain MapKit fallback")
        check(!provider.shouldFetchFallback(for: "Moscow", localResultCount: provider.localResults(matching: "Moscow", excluding: []).count), "Existing weak-inclusive five-result remote threshold is preserved")

        // Exercise actual CityStore load/save with injected in-memory I/O and redirected directories.
        let storageFixture = try IsolatedCityStoreFixture([london.asCity, modernRemote])
        defer { storageFixture.removeCreatedDirectories() }
        let actualStore = CityStore(fileManager: storageFixture.fileManager, storage: storageFixture.storage)
        check(actualStore.cities == [london.asCity, modernRemote] && storageFixture.primaryWrites == 0, "Actual CityStore loads modern identities without rewriting the primary file")
        actualStore.cities.append(samara.asCity)
        let persisted = try JSONDecoder().decode([City].self, from: storageFixture.files[storageFixture.primaryURL]!)
        check(persisted == [london.asCity, modernRemote, samara.asCity] && storageFixture.primaryWrites == 1, "Actual CityStore append persists imported coordinates and preserves prior records")
        let reloadedStore = CityStore(fileManager: storageFixture.fileManager, storage: storageFixture.storage)
        check(reloadedStore.cities == persisted && storageFixture.primaryWrites == 1, "Actual CityStore reload preserves modern IDs without migration")
        let legacyLondon = City(canonicalCity: .init(id: "old-london", name: "London", timeZoneID: "Europe/London"))
        let legacyNewCity = City(canonicalCity: .init(id: "old-samara", name: "Samara", timeZoneID: "Europe/Samara"))
        let legacyWrongZone = City(canonicalCity: .init(id: "old-london-canada", name: "London", timeZoneID: "America/Toronto"))
        let legacyStorage = try IsolatedCityStoreFixture([legacyLondon, legacyNewCity, legacyWrongZone, modernRemote])
        defer { legacyStorage.removeCreatedDirectories() }
        let migratedStore = CityStore(fileManager: legacyStorage.fileManager, storage: legacyStorage.storage)
        check(migratedStore.cities.map(\.id) == [london.canonicalIdentity,
              CitySearchItem.makeCanonicalIdentity(city: "Samara", country: "", timeZoneIdentifier: "Europe/Samara"),
              CitySearchItem.makeCanonicalIdentity(city: "London", country: "", timeZoneIdentifier: "America/Toronto"), modernRemote.id], "Actual CityStore migrates only safe old matches and preserves unknown/remote identities")
        let migratedSaved = try JSONDecoder().decode([City].self, from: legacyStorage.files[legacyStorage.primaryURL]!)
        check(legacyStorage.primaryWrites == 1 && migratedSaved == migratedStore.cities, "Actual legacy migration is durable in isolated primary storage")

        // Extracted actual identity helpers additionally allow controlled provider-ambiguity fixtures.
        let store = StoreIdentityProbe(provider: provider), oldStore = StoreIdentityProbe(provider: old)
        for city in original.map(\.asCity) + [samara.asCity, modernRemote] {
            check(store.migratedCanonicalID(for: city) == city.id, "Modern saved identity remains verbatim: \(city.id)")
        }
        for record in original {
            check(provider.canonicalIdentityForStoredCity(city: record.city, timeZoneIdentifier: record.timeZoneIdentifier) == record.canonicalIdentity, "Original exact legacy match retained: \(record.id)")
        }
        for (name, country, aliasZone, catalogID) in [("Delhi", "India", "Asia/Calcutta", "delhi-in"), ("Kyiv", "Ukraine", "Europe/Kiev", "kyiv-ua"), ("London", "United Kingdom", "GB", "london-gb")] {
            let approved = item(catalogID)
            check(provider.canonicalIdentityForStoredCity(city: name, timeZoneIdentifier: aliasZone) == approved.canonicalIdentity, "Approved IANA link retains original legacy identity: \(aliasZone)")
            check(provider.canonicalItemForCurrentLocation(city: name, country: country, timeZoneIdentifier: aliasZone)?.id == approved.id, "Approved IANA link retains unique current-location identity: \(aliasZone)")
        }
        check(CityTimeZoneCompatibility.matches("US/Eastern", "America/New_York"), "IANA link graph resolves an approved US alias")
        check(!CityTimeZoneCompatibility.matches("Asia/Shanghai", "Asia/Urumqi") && !CityTimeZoneCompatibility.matches("Europe/London", "Europe/Paris"), "Current offsets do not establish equivalent IANA zones")
        let aliasSaved = City(canonicalCity: .init(id: "city:existing-alias-fixture", name: "Delhi", timeZoneID: "Asia/Calcutta"))
        check(store.migratedCanonicalID(for: aliasSaved) == aliasSaved.id && aliasSaved.timeZoneID == "Asia/Calcutta", "Comparison aliases never rewrite modern saved IDs or time-zone strings")
        check(provider.canonicalIdentityForStoredCity(city: samara.city, timeZoneIdentifier: samara.timeZoneIdentifier) == nil, "New catalog membership does not enlarge legacy migration scope")
        let legacySamara = City(canonicalCity: .init(id: "legacy-samara", name: samara.city, timeZoneID: samara.timeZoneIdentifier))
        check(store.migratedCanonicalID(for: legacySamara) == oldStore.migratedCanonicalID(for: legacySamara), "New-city legacy fallback remains stable across expansion")
        check(provider.canonicalIdentityForStoredCity(city: "London", timeZoneIdentifier: "America/Toronto") == nil, "Legacy migration never assigns UK London from a mismatched time zone")
        check(provider.canonicalIdentityForStoredCity(city: "London", timeZoneIdentifier: "Invalid/Zone") == nil, "Legacy name-only matching does not guess a zone")
        check(provider.canonicalItemForCurrentLocation(city: "Samara", country: "Russia", timeZoneIdentifier: "Europe/Samara")?.canonicalIdentity == samara.canonicalIdentity, "Unambiguous imported current city is canonical")
        check(provider.canonicalItemForCurrentLocation(city: "Springfield", country: "United States", timeZoneIdentifier: "America/Chicago") == nil, "Current location refuses same-country same-zone homonyms")
        check(provider.canonicalItemForCurrentLocation(city: "London", country: "United Kingdom", timeZoneIdentifier: "America/Toronto") == nil, "Current location never falls through a time-zone mismatch")

        let synthetic = try syntheticProvider([
            CitySearchItem(id: "bangkok-th", city: "Legacy Town", country: "Thailand", timeZoneIdentifier: "Asia/Bangkok", aliases: ["shared alias", "ambiguous alias"], canonicalID: "city:test:legacy-one"),
            CitySearchItem(id: "chiang-mai-th", city: "Legacy Town", country: "Thailand", timeZoneIdentifier: "Asia/Bangkok", aliases: ["shared alias", "ambiguous alias"], canonicalID: "city:test:legacy-two"),
            CitySearchItem(id: "test-zone-a", city: "Zoneville", country: "United States", timeZoneIdentifier: "America/Chicago", aliases: [], canonicalID: "city:test:zone-a"),
            CitySearchItem(id: "test-zone-b", city: "Zoneville", country: "United States", timeZoneIdentifier: "America/New_York", aliases: [], canonicalID: "city:test:zone-b"),
            CitySearchItem(id: "test-zone-c", city: "Samezone", country: "United States", timeZoneIdentifier: "America/Chicago", aliases: ["sole alias"], canonicalID: "city:test:zone-c"),
            CitySearchItem(id: "test-zone-d", city: "Samezone", country: "United States", timeZoneIdentifier: "America/Chicago", aliases: [], canonicalID: "city:test:zone-d"),
            CitySearchItem(id: "test-alias-exact", city: "shared alias", country: "Thailand", timeZoneIdentifier: "Asia/Bangkok", aliases: [], canonicalID: "city:test:exact-before-alias"),
            CitySearchItem(id: "test-alias-only", city: "Other Town", country: "Thailand", timeZoneIdentifier: "Asia/Bangkok", aliases: ["Legacy Town"], canonicalID: "city:test:weaker-alias")
        ])
        check(synthetic.canonicalIdentityForStoredCity(city: "Legacy Town", timeZoneIdentifier: "Asia/Bangkok") == nil, "Ambiguous frozen-scope legacy fixture never picks its first row")
        check(synthetic.canonicalItemForCurrentLocation(city: "Legacy Town", country: "Thailand", timeZoneIdentifier: "Asia/Bangkok") == nil, "Ambiguous exact current-location tier stops before fallback")
        check(synthetic.canonicalItemForCurrentLocation(city: "shared alias", country: "Thailand", timeZoneIdentifier: "Asia/Bangkok")?.canonicalIdentity == "city:test:exact-before-alias", "One exact current-location result wins before ambiguous aliases")
        check(synthetic.canonicalItemForCurrentLocation(city: "ambiguous alias", country: "Thailand", timeZoneIdentifier: "Asia/Bangkok") == nil, "Ambiguous alias tier never picks its first row")
        check(synthetic.canonicalItemForCurrentLocation(city: "sole alias", country: "United States", timeZoneIdentifier: "America/Chicago")?.canonicalIdentity == "city:test:zone-c", "Unique same-zone alias remains supported")
        check(synthetic.canonicalItemForCurrentLocation(city: "sole alias", country: "United States", timeZoneIdentifier: "America/New_York") == nil, "Alias lookup respects the provided time zone")
        var missingZone = MKMapItem("Zoneville", country: "United States", zone: "America/Chicago"); missingZone.timeZone = nil
        check(synthetic.citySearchItem(from: missingZone, idPrefix: "test") == nil, "Known ambiguous city/country cannot supply a missing remote time zone")
        var sameZone = MKMapItem("Samezone", country: "United States", zone: "America/Chicago"); sameZone.timeZone = nil
        check(synthetic.citySearchItem(from: sameZone, idPrefix: "test")?.timeZoneIdentifier == "America/Chicago", "Repeated same-zone entities retain a nonambiguous fallback zone")

        // Fail both fake network stages; valid local data must survive verbatim.
        for query in ["Samara", "Qingyuan", "Jac", "Jack", "Cambridge"] {
            let local = provider.localResults(matching: query, excluding: [])
            let completionCount = MKLocalSearchCompleter.started.count, searchCount = MKLocalSearch.started.count
            let task = Task { await provider.fallbackMergedResults(matching: query, localResults: local, excluding: []) }
            if (2...6).contains(CitySearchProvider.normalize(query).count) {
                await wait { MKLocalSearchCompleter.started.count > completionCount }
                MKLocalSearchCompleter.started.last!.fail()
            }
            await wait { MKLocalSearch.started.count > searchCount }
            MKLocalSearch.started.last!.fail()
            check(await task.value == local, "Remote errors preserve valid local rows: \(query)")
        }
        let remoteSamara = RegressionTests.remote("Samara", "Russia", "RU", 53.1959, 50.1002, "Europe/Samara", place: "synthetic-provider-place")
        let mergedSamara = CitySearchDeduplicator.merge(local: [samara], remote: [remoteSamara], catalog: catalog)
        check(mergedSamara.count == 2 && mergedSamara[0] == samara, "An imported source identity is not merged with an unverified remote place by name")

        let night = NightCityLights(catalog: catalog)
        let base = night.lights(savedCities: [])
        check(base.count == 152 && base.map(\.id) == lights.map(\.id), "Expanded registry keeps exactly the original ordered decorative base")
        check(zip(base, lights).allSatisfy { light, expected in light.coordinate == .init(latitude: expected.latitude, longitude: expected.longitude) }, "All decorative base WGS84 points unchanged")
        check(zip(base, positions).allSatisfy { light, expected in light.id == expected.id && Double(light.position.x) == expected.projected_x_float && Double(light.position.y) == expected.projected_y_float }, "All decorative projected Float positions unchanged")
        check(night.lights(savedCities: [london.asCity]).count == 152, "An original saved city already in the seen set adds no light")
        check(night.lights(savedCities: [samara.asCity]).count == 153, "A newly saved imported city remains a dynamic light")
        let noSamaraCoordinates = City(canonicalCity: samara.asCity.canonicalCity)
        check(night.lights(savedCities: [noSamaraCoordinates]).count == 153, "New catalog ID can recover dynamic-light coordinates from registry")
        check(night.lights(savedCities: [samara.asCity, noSamaraCoordinates]).count == 153, "Repeated saved identity adds one dynamic light")
        check(night.lights(savedCities: [modernRemote]).last?.id == "saved:" + modernRemote.id, "A modern remote identity remains a dynamic light")
        check(night.lights(savedCities: [misleadingRemote]).count == 152, "Missing remote geography is not guessed for decorative lights")
        check(NightCityLights.Style.diameter == 1 && NightCityLights.Style.brightness == 0.65 && NightCityLights.Style.invisibleElevation == -3 && NightCityLights.Style.fullElevation == -9, "Original light dimensions, brightness and fade endpoints unchanged")
        check(NightCityLights.Style.color == SIMD3<Float>(1, 244/255, 214/255), "Original light color unchanged")
        check(NightCityLights.visibility(elevation: -3) == 0 && NightCityLights.visibility(elevation: -9) == 1 && NightCityLights.visibility(elevation: -6) == 0.5, "Original smooth light fade unchanged")
        print("PASS: \(checks) expanded catalog, migration, local/remote, geography and night-light integration checks")
    }

    static func syntheticProvider(_ items: [CitySearchItem]) throws -> CitySearchProvider {
        let root = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Hours-CatalogFixture-" + UUID().uuidString + ".bundle")
        let resources = root.appendingPathComponent("Contents/Resources")
        try FileManager.default.createDirectory(at: resources, withIntermediateDirectories: true)
        let info: [String: Any] = ["CFBundleIdentifier": "ai.srgmnk.hours.tests.synthetic", "CFBundleName": "SyntheticCatalog", "CFBundleVersion": "1", "CFBundlePackageType": "BNDL"]
        try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0).write(to: root.appendingPathComponent("Contents/Info.plist"))
        try JSONEncoder().encode(items).write(to: resources.appendingPathComponent("cities.json"))
        let provider = CitySearchProvider(bundle: Bundle(url: root)!)
        try FileManager.default.removeItem(at: root)
        return provider
    }
}
