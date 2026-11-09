import Foundation

/// Actual MapKit responses replayed through the production provider with controllable callbacks.
/// Fixture provenance distinguishes recorded evidence from deliberately adversarial variations.
@main struct CitySearchQualityTests {
    static var checks = 0
    static func check(_ condition: Bool, _ label: String) {
        if !condition { FileHandle.standardError.write(Data(("FAIL quality: " + label + "\n").utf8)) }
        precondition(condition, label)
        checks += 1
    }
    static func wait(_ condition: () -> Bool) async {
        let deadline = Date().addingTimeInterval(10)
        while !condition() {
            precondition(Date() < deadline, "Timed out awaiting fake MapKit callback")
            await Task.yield()
        }
    }

    struct RecordedMapItem: Decodable {
        let name: String?
        let cityName: String?
        let countryName: String?
        let countryCode: String?
        let latitude: Double
        let longitude: Double
        let timeZone: String?
        let identifier: String?
        let alternateIdentifiers: [String]
        let cityWithContext: String?
        let fullCityContext: String?
        let fullAddress: String?
        let shortAddress: String?
        let poi: String?
        let placemark: Placemark
        struct Placemark: Decodable {
            let locality: String?
            let administrativeArea: String?
            let subAdministrativeArea: String?
            let subLocality: String?
            let country: String?
            let isoCountryCode: String?
            let thoroughfare: String?
            let subThoroughfare: String?
            let inlandWater: String?
            let ocean: String?
        }
        var fake: MKMapItem {
            var item = MKMapItem(cityName ?? "", country: countryName ?? "", zone: timeZone ?? "")
            item.name = name
            item.identifier = identifier.map { .init(rawValue: $0) }
            item.alternateIdentifiers = Set(alternateIdentifiers.map { .init(rawValue: $0) })
            item.location.coordinate = .init(latitude: latitude, longitude: longitude)
            item.pointOfInterestCategory = poi.map { .init(rawValue: $0) }
            item.address = .init(shortAddress: shortAddress, fullAddress: fullAddress)
            item.addressRepresentations = .init(cityName: cityName, region: countryCode.map { Locale.Region($0) },
                fullContext: fullCityContext, regionName: countryName, context: cityWithContext)
            item.placemark = .init(locality: placemark.locality, administrativeArea: placemark.administrativeArea,
                subAdministrativeArea: placemark.subAdministrativeArea, subLocality: placemark.subLocality,
                country: placemark.country, isoCountryCode: placemark.isoCountryCode,
                thoroughfare: placemark.thoroughfare, subThoroughfare: placemark.subThoroughfare,
                inlandWater: placemark.inlandWater, ocean: placemark.ocean)
            return item
        }
    }
    struct Completion: Decodable { let title: String; let subtitle: String; let mapItems: [RecordedMapItem] }
    struct QueryFixture: Decodable { let query: String; let completions: [Completion] }
    struct FixtureFile: Decodable { let provenance: String; let queries: [QueryFixture] }

    static func replay(_ fixture: QueryFixture, local: [CitySearchItem],
                       start: () -> Task<[CitySearchItem], Never>) async -> [CitySearchItem] {
        let completionCount = MKLocalSearchCompleter.started.count
        var requestCount = MKLocalSearch.started.count
        let task = start()
        let normalizedCount = CitySearchProvider.normalize(fixture.query).count
        let usesCompleter = (2...6).contains(normalizedCount)
        if usesCompleter {
            await wait { MKLocalSearchCompleter.started.count == completionCount + 1 }
            let sender = MKLocalSearchCompleter.started.last!
            sender.results = fixture.completions.map { MKLocalSearchCompletion(title: $0.title, subtitle: $0.subtitle) }
            sender.queuedDelegate?.completerDidUpdateResults(sender)
            for completion in fixture.completions.prefix(5) {
                await wait { MKLocalSearch.started.count == requestCount + 1 }
                MKLocalSearch.started.last!.complete(completion.mapItems.map(\.fake))
                requestCount += 1
            }
        } else {
            await wait { MKLocalSearch.started.count == requestCount + 1 }
            MKLocalSearch.started.last!.complete(fixture.completions.flatMap(\.mapItems).map(\.fake))
        }
        return await task.value
    }

    static func main() async throws {
        try await RegressionTests.main()
        let root = Bundle.main.bundleURL
        let catalog = try JSONDecoder().decode([CitySearchItem].self, from: Data(contentsOf: root.appendingPathComponent("cities.json")))
        let fixtureFile = try JSONDecoder().decode(FixtureFile.self, from: Data(contentsOf: root.appendingPathComponent("samara-recorded.json")))
        let provider = CitySearchProvider.shared
        let samara = catalog.first { $0.id == "geonames-499099" }!
        let localCoordinate = LocalCityCoordinates.byCatalogID[samara.id]!
        var resultLists: [[String: Any]] = []
        for fixture in fixtureFile.queries {
            let local = provider.localResults(matching: fixture.query, excluding: [])
            let beforeRequests = MKLocalSearch.started.count
            let merged = await replay(fixture, local: local) {
                Task { await provider.fallbackMergedResults(matching: fixture.query, localResults: local, excluding: []) }
            }
            check(merged.filter { $0.canonicalIdentity == samara.canonicalIdentity }.count == 1, "One selected local Samara identity: \(fixture.query)")
            check(merged.filter { $0.city == "Samara" && $0.country == "Russia" }.count == 1, "One displayed Samara Russia representation: \(fixture.query)")
            let retained = merged.first { $0.canonicalIdentity == samara.canonicalIdentity }!
            check(retained == samara && retained.id == samara.id, "Catalog presentation and identity win: \(fixture.query)")
            check(retained.asCity.latitude == localCoordinate.latitude && retained.asCity.longitude == localCoordinate.longitude,
                  "A merged selection preserves catalog WGS84 coordinates: \(fixture.query)")
            check(!merged.contains { $0.city == "Zhanakorgan District" || $0.city == "Samara Oblast" }, "Administrative/road substitutions excluded: \(fixture.query)")
            check(Array(merged.prefix(local.count)) == local, "Local publication order remains stable: \(fixture.query)")
            check(MKLocalSearch.started.count - beforeRequests == min(5, fixture.completions.count), "No additional resolver request stage: \(fixture.query)")
            let oldRows = DisplayResult.rows(for: local)
            check(Array(DisplayResult.rows(for: merged).prefix(local.count)).map(\.id) == oldRows.map(\.id), "Existing local row IDs do not jump when remote arrives: \(fixture.query)")
            resultLists.append(["query":fixture.query,"local":local.map(description),"merged":merged.map(description)])
        }

        let townFixtures = try JSONDecoder().decode(FixtureFile.self, from: Data(contentsOf: root.appendingPathComponent("small-cities-recorded.json")))
        for fixture in townFixtures.queries {
            let local = provider.localResults(matching: fixture.query, excluding: [])
            let merged = await replay(fixture, local: local) {
                Task { await provider.fallbackMergedResults(matching: fixture.query, localResults: local, excluding: []) }
            }
            check(Array(merged.prefix(local.count)) == local, "Recorded town/local publication prefix remains stable: \(fixture.query)")
            let expectedName = CitySearchProvider.normalize(fixture.completions.first!.mapItems.first!.name!)
            check(merged.contains { CitySearchProvider.normalize($0.city).hasPrefix(expectedName) }, "Recorded remote settlement remains discoverable: \(fixture.query)")
            if ["Brixham", "Uglich", "Totnes"].contains(fixture.query) {
                check(local.isEmpty, "Small-town fixture is outside local catalog: \(fixture.query)")
                let first = merged.first!
                let encoded = try JSONEncoder().encode(first.asCity)
                let restored = try JSONDecoder().decode(City.self, from: encoded)
                check(restored == first.asCity && restored.latitude != nil && restored.longitude != nil,
                      "Small-town selection preserves geographic identity and coordinates: \(fixture.query)")
            }
            if fixture.query == "Uglich" {
                let village = fixture.completions.flatMap(\.mapItems).first { $0.name?.hasPrefix("деревня") == true }!
                check(merged.contains { $0.city == village.name && $0.country == "Russia" },
                      "MapKit's legitimate D Uglichi to деревня Угличи spelling bridge remains discoverable")
            }
            check(!merged.contains { $0.city == "Thane" || $0.city == "England" }, "Query matched address cannot replace the settlement name: \(fixture.query)")
            if ["Qingyuan", "清远", "Cambridge"].contains(fixture.query) {
                check(merged == local && merged.allSatisfy { $0.geographicalEvidence == nil }, "Reviewed cross-source city duplicate preserves exact local items: \(fixture.query)")
            }
            resultLists.append(["query":fixture.query,"local":local.map(description),"merged":merged.map(description)])
        }

        let transliterated = try JSONDecoder().decode(FixtureFile.self, from: Data(contentsOf: root.appendingPathComponent("transliterated-recorded.json")))
        for fixture in transliterated.queries {
            let local = provider.localResults(matching: fixture.query, excluding: [])
            check(local.isEmpty, "Russian small-town spelling has no local alias metadata")
            let merged = await replay(fixture, local: local) {
                Task { await provider.fallbackMergedResults(matching: fixture.query, localResults: local, excluding: []) }
            }
            check(merged.contains { $0.city == "Uglich" && $0.country == "Russia" }, "A trustworthy noncatalog transliteration survives with no MapKit highlights")
            resultLists.append(["query":fixture.query,"local":local.map(description),"merged":merged.map(description)])
        }
        // Synthetic direct-query variant uses the actual recorded Uglich map item.
        // This tests validation coverage, not whether a live request for this phrase succeeds.
        if let recorded = transliterated.queries.first?.completions.first {
            let direct = QueryFixture(query: "Углич, Россия", completions: [recorded])
            let merged = await replay(direct, local: []) {
                Task { await provider.fallbackMergedResults(matching: direct.query, localResults: [], excluding: []) }
            }
            check(merged.contains { $0.city == "Uglich" && $0.country == "Russia" }, "Direct unknown exonym query preserves independently corroborated city-level names")
        }
        let additional = try JSONDecoder().decode(FixtureFile.self, from: Data(contentsOf: root.appendingPathComponent("additional-reviewed-recorded.json")))
        for fixture in additional.queries {
            let local = provider.localResults(matching: fixture.query, excluding: [])
            let merged = await replay(fixture, local: local) {
                Task { await provider.fallbackMergedResults(matching: fixture.query, localResults: local, excluding: []) }
            }
            check(merged == local && merged.count == 2 && Set(merged.map(\.canonicalIdentity)).count == 2,
                  "Reviewed Missouri representation collapses while Illinois and Missouri remain distinct")
            check(merged.allSatisfy { item in
                guard let original = local.first(where: { $0.id == item.id }) else { return false }
                return item.geographicalEvidence == nil && item.asCity == original.asCity
            },
                  "Springfield local entries retain their exact catalog presentation")
            resultLists.append(["query":fixture.query,"local":local.map(description),"merged":merged.map(description)])
        }

        // Synthetic negative controls deliberately alter recorded geography; they are not live observations.
        let base = fixtureFile.queries[0].completions[0].mapItems[0]
        let city = provider.citySearchItem(from: base.fake, idPrefix: "test")!
        func merge(_ items: [CitySearchItem], catalog override: [CitySearchItem]? = nil) -> [CitySearchItem] {
            CitySearchDeduplicator.merge(local: [samara], remote: items, catalog: override ?? catalog)
        }
        check(merge([city]).count == 1, "Recorded remote Samara is the reviewed local entity")
        check(provider.citySearchItem(from: base.fake, idPrefix: "test", matching: "Куйбышев") != nil,
              "A verified historical catalog alias remains relevant to its current city name")
        var watersideCity = base.fake
        watersideCity.placemark.inlandWater = "Volga"
        check(provider.citySearchItem(from: watersideCity, idPrefix: "test", matching: "Samara") != nil,
              "Nearby water metadata alone does not reject a genuine populated city")
        var sparseTown = MKMapItem("Parent District", country: "Russia", zone: "Europe/Samara")
        sparseTown.name = "Small Village"
        sparseTown.placemark.locality = nil
        sparseTown.placemark.subAdministrativeArea = "Parent District"
        sparseTown.address = .init(shortAddress: "Small Village", fullAddress: "Small Village, Parent District, Russia")
        sparseTown.addressRepresentations = .init(cityName: "Parent District", region: Locale.Region("RU"),
            fullContext: "Small Village, Parent District, Russia", regionName: "Russia", context: "Small Village, Parent District, Russia")
        check(provider.citySearchItem(from: sparseTown, idPrefix: "test", matching: "Small Village")?.city == "Small Village",
              "A sparse small settlement with corroborated full city context is not rejected for its containing district")
        let unrelatedCity = townFixtures.queries.first { $0.query == "Uglich" }!.completions[0].mapItems[0].fake
        check(provider.citySearchItem(from: unrelatedCity, idPrefix: "test", matching: "Samara") == nil,
              "A known catalog query cannot accept an unrelated corroborated city")
        var wrongCountry = base.fake
        wrongCountry.addressRepresentations?.region = Locale.Region("KZ")
        if let candidate = provider.citySearchItem(from: wrongCountry, idPrefix: "test") {
            check(merge([candidate]).count == 2, "Country-code mismatch cannot merge by name and zone")
        } else {
            check(true, "Inconsistent country evidence is rejected before deduplication")
        }
        var wrongZone = base.fake
        wrongZone.timeZone = TimeZone(identifier: "Europe/Moscow")
        check(merge([provider.citySearchItem(from: wrongZone, idPrefix: "test")!]).count == 2, "Time-zone mismatch remains distinct")
        var moved = base.fake
        moved.location.coordinate.longitude += 0.01
        check(merge([provider.citySearchItem(from: moved, idPrefix: "test")!]).count == 2, "An unreviewed nearby anchor is not a municipality identity")
        var far = base.fake
        far.location.coordinate = .init(latitude: 1, longitude: 2)
        check(merge([provider.citySearchItem(from: far, idPrefix: "test")!]).count == 2, "Remote text at unrelated geography is not an equivalent catalog city")
        var poi = base.fake
        poi.name = "Samara Restaurant"
        poi.pointOfInterestCategory = .init(rawValue: "restaurant")
        if let candidate = provider.citySearchItem(from: poi, idPrefix: "test") {
            check(merge([candidate]).count == 2, "POI at a catalog anchor is not the city")
        } else {
            check(true, "Non-city POI is rejected before deduplication")
        }
        let ambiguous = CitySearchItem(id: "synthetic-other-samara", city: "Samara", country: "Russia",
            timeZoneIdentifier: "Europe/Samara", aliases: [], canonicalID: "city:synthetic:other-samara")
        check(merge([ambiguous]).count == 2, "Name/country/time zone without geography does not merge")
        let earlier = RegressionTests.remote("Earlier caption", "Russia", "RU", 53.3, 50.4, "Europe/Samara", place: "provider-samara-A")
        var bridgeItem = base.fake
        bridgeItem.alternateIdentifiers = [.init(rawValue: "provider-samara-A")]
        let bridge = provider.citySearchItem(from: bridgeItem, idPrefix: "test")!
        let oldRemoteIdentity = CitySearchDeduplicator.merge(local: [], remote: [earlier], catalog: catalog)[0].canonicalIdentity
        let bridged = CitySearchDeduplicator.merge(local: [samara], remote: [earlier, bridge, earlier], catalog: catalog, existingCanonicalIDs: [oldRemoteIdentity])
        check(bridged == [samara] && bridged[0].geographicalEvidence == nil && bridged[0].asCity == samara.asCity,
              "Verified provider-ID bridge keeps exact pure catalog item across combined groups")
        check(CitySearchDeduplicator.merge(local: bridged, remote: [earlier, bridge], catalog: catalog) == bridged,
              "Repeating a complete verified provider-ID bridge is idempotent")

        let queryNames = ["Samara", "Самара", "Qingyuan", "清远", "London", "Moscow", "Tokyo", "Bangkok", "Springfield", "Cambridge", "Brixham", "Uglich", "Totnes", "Ja", "Jac", "Jack"]
        var localTimes: [Double] = []
        var queryCounts: [[String: Any]] = []
        for query in queryNames {
            let initial = provider.localResults(matching: query, excluding: [])
            for _ in 0..<20 {
                let start = Date.timeIntervalSinceReferenceDate
                let result = provider.localResults(matching: query, excluding: [])
                localTimes.append((Date.timeIntervalSinceReferenceDate-start)*1000)
                check(result == initial, "Unchanged deterministic local order: \(query)")
            }
            queryCounts.append(["query":query,"count":initial.count,"ids":initial.map(\.id),"remoteEligible":provider.shouldFetchFallback(for: query, localResultCount: initial.count)])
        }
        let springs = provider.localResults(matching: "Springfield", excluding: [])
        check(Set(springs.map(\.canonicalIdentity)).count == 2, "Illinois and Missouri Springfield remain distinct")
        let cams = provider.localResults(matching: "Cambridge", excluding: [])
        check(Set(cams.map(\.country)).count == 2, "Cambridge countries remain independently selectable")
        // A cancelled Russian query's queued callbacks must not affect a newer English query.
        let russianLocal = provider.localResults(matching: "Самара", excluding: [])
        let englishLocal = provider.localResults(matching: "Samara", excluding: [])
        let completersBefore = MKLocalSearchCompleter.started.count
        let stale = Task { await provider.fallbackMergedResults(matching: "Самара", localResults: russianLocal, excluding: []) }
        await wait { MKLocalSearchCompleter.started.count == completersBefore + 1 }
        let staleSender = MKLocalSearchCompleter.started.last!
        stale.cancel()
        let current = Task { await provider.fallbackMergedResults(matching: "Samara", localResults: englishLocal, excluding: []) }
        await wait { MKLocalSearchCompleter.started.count == completersBefore + 2 }
        let currentSender = MKLocalSearchCompleter.started.last!
        staleSender.emit(["Zhanakorgan District"])
        staleSender.fail()
        let requestsBefore = MKLocalSearch.started.count
        currentSender.results = [MKLocalSearchCompletion(title: "Samara", subtitle: "Samara Oblast, Russia")]
        currentSender.queuedDelegate?.completerDidUpdateResults(currentSender)
        await wait { MKLocalSearch.started.count == requestsBefore + 1 }
        MKLocalSearch.started.last!.complete([base.fake])
        let staleResult = await stale.value
        let currentResult = await current.value
        check(staleResult == russianLocal, "Cancelled Russian query returns only its prior local values")
        check(Array(currentResult.prefix(englishLocal.count)) == englishLocal && currentResult.filter { $0.city == "Samara" && $0.country == "Russia" }.count == 1,
              "New query keeps its own stable results after stale foreign callbacks")
        check(currentSender.cancelCount == 1 && MKLocalSearch.started.count == requestsBefore + 1,
              "Stale callback cannot cancel the newer request or start an extra resolution")
        // Rejected successful candidates must not create an extra resolution stage.
        if let invalidRecord = fixtureFile.queries.flatMap(\.completions).flatMap(\.mapItems).first(where: { $0.placemark.inlandWater != nil }) {
            let startCompleters = MKLocalSearchCompleter.started.count
            let startSearches = MKLocalSearch.started.count
            var finished = false
            let invalidOnly = Task {
                let result = await provider.fallbackMergedResults(matching: "Самара", localResults: russianLocal, excluding: [])
                finished = true
                return result
            }
            await wait { MKLocalSearchCompleter.started.count == startCompleters + 1 }
            let sender = MKLocalSearchCompleter.started.last!
            sender.results = [MKLocalSearchCompletion(title: "Самара", subtitle: "Dnipropetrovsk Oblast, Ukraine")]
            sender.queuedDelegate?.completerDidUpdateResults(sender)
            await wait { MKLocalSearch.started.count == startSearches + 1 }
            MKLocalSearch.started.last!.complete([invalidRecord.fake])
            await wait { finished || MKLocalSearch.started.count > startSearches + 1 }
            let additionalRequests = MKLocalSearch.started.count - startSearches
            if !finished { invalidOnly.cancel() }
            let rejected = await invalidOnly.value
            check(additionalRequests == 1, "Rejecting resolved non-city candidates does not add a direct search request")
            check(rejected == russianLocal, "Invalid-only remote candidates preserve local rows")
        }
        let failureCompleters = MKLocalSearchCompleter.started.count
        let failureSearches = MKLocalSearch.started.count
        let failedResolution = Task { await provider.fallbackMergedResults(matching: "Samara", localResults: englishLocal, excluding: []) }
        await wait { MKLocalSearchCompleter.started.count == failureCompleters + 1 }
        MKLocalSearchCompleter.started.last!.emit(["Samara"])
        await wait { MKLocalSearch.started.count == failureSearches + 1 }
        MKLocalSearch.started.last!.fail()
        await wait { MKLocalSearch.started.count == failureSearches + 2 }
        MKLocalSearch.started.last!.complete([base.fake])
        let failureFallback = await failedResolution.value
        check(failureFallback == englishLocal, "Actual resolution failures retain the original direct fallback and local identity")
        check(MKLocalSearch.started.count == failureSearches + 2, "Failure fallback uses exactly the pre-existing request stages")
        var invalidCoordinate = base.fake
        invalidCoordinate.location.coordinate.latitude = .nan
        var missingTimeZone = MKMapItem("MissingZoneTown", country: "United States", zone: "Invalid/Zone")
        missingTimeZone.timeZone = nil
        for (label, rawItems) in [("empty successful response", [MKMapItem]()), ("invalid coordinates", [invalidCoordinate]), ("missing unresolved time zone", [missingTimeZone])] {
            let completerCount = MKLocalSearchCompleter.started.count
            let searchCount = MKLocalSearch.started.count
            let task = Task { await provider.fallbackMergedResults(matching: "Samara", localResults: englishLocal, excluding: []) }
            await wait { MKLocalSearchCompleter.started.count == completerCount + 1 }
            MKLocalSearchCompleter.started.last!.emit(["Samara"])
            await wait { MKLocalSearch.started.count == searchCount + 1 }
            MKLocalSearch.started.last!.complete(rawItems)
            await wait { MKLocalSearch.started.count == searchCount + 2 }
            MKLocalSearch.started.last!.complete([base.fake])
            let result = await task.value
            check(result == englishLocal && MKLocalSearch.started.count == searchCount + 2, "Pre-existing direct fallback is retained for \(label)")
        }
        let directCount = MKLocalSearch.started.count
        let cleared = Task { await provider.fallbackMergedResults(matching: "Brixham", localResults: [], excluding: []) }
        await wait { MKLocalSearch.started.count == directCount + 1 }
        let clearingSearch = MKLocalSearch.started.last!
        cleared.cancel()
        let clearedResult = await cleared.value
        clearingSearch.complete([base.fake])
        check(clearedResult.isEmpty && clearingSearch.cancelCount == 1, "Clearing during direct resolution cancels and prevents late publication")
        for query in ["London", "Moscow", "Tokyo", "Bangkok", "Ja"] {
            let local = provider.localResults(matching: query, excluding: [])
            let count = MKLocalSearch.started.count, completers = MKLocalSearchCompleter.started.count
            let result = await provider.fallbackMergedResults(matching: query, localResults: local, excluding: [])
            check(result == local && MKLocalSearch.started.count == count && MKLocalSearchCompleter.started.count == completers,
                  "Existing fallback threshold and local-first flow retained: \(query)")
        }
        var output: [String: Any] = ["checks":checks,"fixtureProvenance":fixtureFile.provenance,"beforeAfterLists":resultLists,
            "localQueries":queryCounts,"localLatency":stats(localTimes),"environment":"Optimized Swift executable on Mac; not physical iPhone"]
        #if QUALITY_BASELINE
        let baseline = BaselineCitySearchProvider()
        let raw = fixtureFile.queries[0].completions.compactMap { $0.mapItems.first }.compactMap { baseline.citySearchItem(from: $0.fake, idPrefix: "fixture") }
        var before: [Double] = [], after: [Double] = []
        var benchmarkChecksum = 0
        for _ in 0..<10 {
            benchmarkChecksum += BaselineCitySearchDeduplicator.merge(local: [samara], remote: raw, catalog: catalog).count
            benchmarkChecksum += CitySearchDeduplicator.merge(local: [samara], remote: raw, catalog: catalog).count
        }
        for _ in 0..<200 {
            let start = Date.timeIntervalSinceReferenceDate
            benchmarkChecksum += BaselineCitySearchDeduplicator.merge(local: [samara], remote: raw, catalog: catalog).count
            before.append((Date.timeIntervalSinceReferenceDate-start)*1000)
            let next = Date.timeIntervalSinceReferenceDate
            benchmarkChecksum += CitySearchDeduplicator.merge(local: [samara], remote: raw, catalog: catalog).count
            after.append((Date.timeIntervalSinceReferenceDate-next)*1000)
        }
        output["dedupProcessing"] = ["before":stats(before),"after":stats(after),"remoteCount":raw.count,"catalogCount":catalog.count]
        let records = fixtureFile.queries.flatMap { fixture in fixture.completions.flatMap { completion in
            completion.mapItems.map { (fixture.query, $0) }
        } }
        var beforeValidation: [Double] = [], afterValidation: [Double] = []
        for _ in 0..<100 {
            let start = Date.timeIntervalSinceReferenceDate
            for (_, record) in records { benchmarkChecksum += baseline.citySearchItem(from: record.fake, idPrefix: "fixture") == nil ? 0 : 1 }
            beforeValidation.append((Date.timeIntervalSinceReferenceDate-start)*1000)
            let next = Date.timeIntervalSinceReferenceDate
            for (query, record) in records {
                let item = provider.citySearchItem(from: record.fake, idPrefix: "fixture", matching: query)
                benchmarkChecksum += item == nil ? 0 : 1
                if item == nil { benchmarkChecksum += provider.hasResolvableAddress(record.fake) ? 1 : 0 }
            }
            afterValidation.append((Date.timeIntervalSinceReferenceDate-next)*1000)
        }
        output["validationProcessing"] = ["before":stats(beforeValidation),"after":stats(afterValidation),"batchRecords":records.count,
            "scope":"Conversion and query relevance plus legacy request-eligibility check on rejected completer records; fake fields, no network/async callback latency."]
        var beforeLocal: [Double] = [], afterLocal: [Double] = []
        for query in queryNames {
            for _ in 0..<20 {
                let start = Date.timeIntervalSinceReferenceDate
                benchmarkChecksum += baseline.localResults(matching: query, excluding: []).count
                beforeLocal.append((Date.timeIntervalSinceReferenceDate-start)*1000)
                let next = Date.timeIntervalSinceReferenceDate
                benchmarkChecksum += provider.localResults(matching: query, excluding: []).count
                afterLocal.append((Date.timeIntervalSinceReferenceDate-next)*1000)
            }
        }
        output["localSearchBeforeAfter"] = ["before":stats(beforeLocal),"after":stats(afterLocal)]
        output["benchmarkChecksum"] = benchmarkChecksum
        #endif
        if let path = ProcessInfo.processInfo.environment["QUALITY_OUTPUT_DIR"] {
            try JSONSerialization.data(withJSONObject: output,options:[.prettyPrinted,.sortedKeys]).write(to: URL(fileURLWithPath:path).appendingPathComponent("quality-results.json"))
        }
        print("PASS: \(checks) recorded search-quality, identity, local-order and threshold checks")
    }

    static func description(_ item: CitySearchItem) -> [String: Any] {
        ["id":item.id,"canonicalID":item.canonicalIdentity,"city":item.city,"country":item.country,
         "timeZone":item.timeZoneIdentifier,"latitude":item.asCity.latitude.map { $0 as Any } ?? NSNull(),"longitude":item.asCity.longitude.map { $0 as Any } ?? NSNull()]
    }
    static func stats(_ times: [Double]) -> [String: Any] {
        let sorted = times.sorted()
        return ["samples":sorted.count,"p50_ms":sorted[(sorted.count-1)/2],"p95_ms":sorted[min(sorted.count-1,Int(ceil(Double(sorted.count)*0.95))-1)],"max_ms":sorted.last!]
    }
}
