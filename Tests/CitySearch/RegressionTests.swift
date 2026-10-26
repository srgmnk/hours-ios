import Foundation

@main struct RegressionTests {
    static var checks = 0
    static func check(_ value: Bool, _ label: String) {
        precondition(value, label)
        checks += 1
    }
    static func wait(_ condition: () -> Bool) async {
        let deadline = Date().addingTimeInterval(5)
        while !condition() {
            precondition(Date() < deadline, "Async test timed out")
            await Task.yield()
        }
    }
    static func remote(_ city: String, _ country: String, _ code: String,
                       _ latitude: Double, _ longitude: Double, _ zone: String,
                       context: String? = nil, place: String? = nil, aliases: [String] = []) -> CitySearchItem {
        let context = context ?? "\(city), \(country)"
        return CitySearchItem(id: "remote-\(city)|\(country)|\(zone)", city: city, country: country,
            timeZoneIdentifier: zone, aliases: [], geographicalEvidence: .init(
                placeIdentifier: place, alternatePlaceIdentifiers: aliases, originalName: city,
                cityName: city, countryCode: code, coordinates: .init(latitude: latitude, longitude: longitude),
                cityWithContext: context, cityWithFullContext: context, fullAddress: context,
                shortAddress: nil, pointOfInterestCategory: nil))
    }
    static func mapItem(_ item: CitySearchItem) -> MKMapItem {
        let e = item.geographicalEvidence!
        var m = MKMapItem(item.city, country: item.country, zone: item.timeZoneIdentifier)
        m.name = e.originalName
        m.location.coordinate = .init(latitude: e.coordinates!.latitude, longitude: e.coordinates!.longitude)
        m.address = .init(shortAddress: nil, fullAddress: e.fullAddress)
        m.addressRepresentations = .init(cityName: e.cityName, region: Locale.Region(e.countryCode!),
                                        fullContext: e.cityWithFullContext, regionName: item.country)
        return m
    }
    static func main() async throws {
        let url = Bundle.main.url(forResource: "cities", withExtension: "json")!
        let catalog = try JSONDecoder().decode([CitySearchItem].self, from: Data(contentsOf: url))
        check(catalog.count == 152, "Use the actual complete catalog")
        func local(_ id: String) -> CitySearchItem { catalog.first { $0.id == id }! }
        func merge(_ local: [CitySearchItem], _ remote: [CitySearchItem], added: Set<String> = []) -> [CitySearchItem] {
            CitySearchDeduplicator.merge(local: local, remote: remote, catalog: catalog, existingCanonicalIDs: added)
        }
        // Coordinates/context recorded from live MapKit responses, 2026-10-26.
        let bangkok = remote("Bangkok", "Thailand", "TH", 13.7537858, 100.4985251, "Asia/Bangkok")
        let moscow = remote("Moscow", "Russia", "RU", 55.7586642, 37.6192919, "Europe/Moscow")
        let moscowUS = remote("Moscow", "United States", "US", 45.0706113, -69.8911705,
                              "America/New_York", context: "Moscow, ME, United States")
        let ma = remote("Springfield", "United States", "US", 42.1038646, -72.5885948,
                        "America/New_York", context: "Springfield, MA, United States")
        let nj = remote("Springfield", "United States", "US", 40.708611, -74.3135367,
                        "America/New_York", context: "Springfield, NJ, United States")
        let bkkLocal = local("bangkok-th"), moscowLocal = local("moscow-ru")
        let b = merge([bkkLocal, local("chiang-mai-th")], [bangkok, bangkok], added: [bkkLocal.canonicalIdentity])
        check(b.count == 2 && b[0] == bkkLocal, "Bangkok duplicates collapse to established catalog record")
        check(b[0].geographicalEvidence != nil, "Retain remote evidence on catalog winner")
        check(b[0].asCity.id == bkkLocal.asCity.id, "Added and persisted catalog identity unchanged")
        let m = merge([moscowLocal, local("saint-petersburg-ru")], [moscow, moscowUS, moscow])
        check(m.count == 3 && m[0] == moscowLocal && m[2].country == "United States", "Moscow countries remain separate")
        check(m.map(\.city) == ["Moscow", "Saint Petersburg", "Moscow"], "Local-first ranking preserved")
        let springs = merge([], [ma, nj, ma])
        check(springs.count == 2, "Repeated remote representation merges, distinct regions survive")
        check(ma.id == nj.id && ma.canonicalIdentity == nj.canonicalIdentity, "Fixture reproduces legacy collision")
        check(springs[0].canonicalIdentity != springs[1].canonicalIdentity, "Distinct same-country same-zone cities independently selectable")
        check(springs[0].asCity.id == springs[0].canonicalIdentity, "Selection persists geographic identity")
        let added = Set([springs[0].canonicalIdentity])
        let again = merge([], [ma, nj, ma], added: added)
        check(again.filter { added.contains($0.canonicalIdentity) }.count == 1, "Only the actual added region has Added state")
        check(merge([bkkLocal], []).first == bkkLocal, "Local-only results unchanged")
        check(merge([], [bangkok]).first == bkkLocal, "Remote-only catalog equivalent uses established ID")
        let raw = CitySearchItem(id: "ambiguous", city: "Springfield", country: "United States",
                                 timeZoneIdentifier: "America/New_York", aliases: [])
        check(merge([], [raw, raw]).count == 2, "Missing evidence preserves ambiguity")
        let moved = remote("Bangkok", "Thailand", "TH", 14, 101, "Asia/Bangkok")
        check(merge([bkkLocal], [moved]).count == 2, "Name/country/time zone do not prove equivalence")
        let localized = remote("Bangkok", "Thaïlande", "TH", 13.7537858, 100.4985251, "Asia/Bangkok")
        check(merge([bkkLocal], [localized]).count == 1, "Verified country code works across country display localization")
        let poi = remote("Bangkok", "Thailand", "TH", 13.7537858, 100.4985251, "Asia/Bangkok", context: "Bangkok Restaurant, Thailand")
        // The actual converter's originalName/context/fullAddress checks prevent substituting a street/POI for a city.
        var fakePOI = mapItem(poi); fakePOI.pointOfInterestCategory = .init(rawValue: "restaurant")
        let p = CitySearchProvider.shared
        let convertedPOI = p.citySearchItem(from: fakePOI, idPrefix: "test")!
        check(merge([bkkLocal], [convertedPOI]).count == 2, "POI at city anchor is not a catalog municipality")
        let placeA = remote("Test", "US", "US", 1, 2, "America/New_York", place: "A")
        let placeB = remote("Test", "US", "US", 3, 4, "America/New_York", place: "B")
        let bridge = remote("Test", "US", "US", 5, 6, "America/New_York", place: "B", aliases: ["A"])
        let original = merge([], [placeA])[0]
        let bridged = merge([], [placeB, placeA, bridge], added: [original.canonicalIdentity])
        check(bridged.count == 1 && bridged[0].canonicalIdentity == original.canonicalIdentity,
              "Provider alternate IDs join groups, retaining already-added identity")
        for _ in 0..<20 {
            let repeated = merge([bkkLocal], [bangkok, ma, nj, ma])
            check(repeated.count == 3, "No accumulation on repeated queries")
            let rows = DisplayResult.rows(for: repeated)
            check(Set(rows.map(\.id)).count == rows.count, "Unique presentation identities")
            check(rows.map(\.item) == repeated.map(Optional.some), "Rows select original merged item")
            check(rows.map(\.id) == DisplayResult.rows(for: merge([bkkLocal], [bangkok, ma, nj, ma])).map(\.id), "Stable repeated row identities")
            check(rows[0].id == DisplayResult.rows(for: [bkkLocal])[0].id, "Local row identity stable when remote arrives")
        }
        // Full current provider with deterministic remote callbacks, including cancellation races.
        check(p.localResults(matching: "Ja", excluding: []).count == 8, "Ja remains local")
        for query in ["Bangkok", "Bangkok"] {
            let start = MKLocalSearch.started.count
            let task = Task { await p.fallbackMergedResults(matching: query, localResults: [bkkLocal], excluding: [], existingCanonicalIDs: [bkkLocal.canonicalIdentity]) }
            await wait { MKLocalSearch.started.count == start + 1 }
            MKLocalSearch.started.last!.complete([mapItem(bangkok), mapItem(bangkok)])
            let result = await task.value
            check(result.count == 1 && result[0] == bkkLocal, "Actual direct fallback merges repeated Bangkok and preserves Added")
        }
        let bridgeOwner = CitySearchProvider.SearchCompleterBridge()
        let a = Task { await bridgeOwner.completions(for: "Jac") }
        await wait { bridgeOwner.activeRequest != nil }
        let oldID = bridgeOwner.activeRequest!.id, oldSender = bridgeOwner.activeRequest!.completer
        let bTask = Task { await bridgeOwner.completions(for: "Jack") }
        await wait { bridgeOwner.activeRequest?.id != oldID }
        let newSender = bridgeOwner.activeRequest!.completer
        a.cancel(); bridgeOwner.finish(requestID: oldID, with: [])
        oldSender.emit(["OLD"]); oldSender.fail()
        check(newSender.cancelCount == 0, "Old cancellation and late callbacks do not affect newer request")
        newSender.emit(["NEW"]); newSender.emit(["DUPLICATE"])
        let av = await a.value, bv = await bTask.value
        check(av.isEmpty && bv.map(\.title) == ["NEW"], "Exactly-once completion under stale callbacks")
        for query in ["Jac", "Jack", "Jac", "Ja"] {
            let count = MKLocalSearchCompleter.started.count
            let task = Task { await p.fallbackMergedResults(matching: query, localResults: [], excluding: []) }
            await wait { MKLocalSearchCompleter.started.count == count + 1 }
            let requestCount = MKLocalSearch.started.count
            task.cancel()
            let result = await task.value
            check(result.isEmpty && MKLocalSearch.started.count == requestCount, "Rapid typing/deletion cancellation never starts fallback")
        }
        let count = MKLocalSearchCompleter.started.count
        let resolve = Task { await p.fallbackMergedResults(matching: "Moscow", localResults: [moscowLocal], excluding: []) }
        await wait { MKLocalSearchCompleter.started.count == count + 1 }
        let requests = MKLocalSearch.started.count
        MKLocalSearchCompleter.started.last!.emit(["Moscow", "Moscow again"])
        await wait { MKLocalSearch.started.count == requests + 1 }
        MKLocalSearch.started.last!.complete([mapItem(moscow)])
        await wait { MKLocalSearch.started.count == requests + 2 }
        MKLocalSearch.started.last!.complete([mapItem(moscow)])
        let resolved = await resolve.value
        check(resolved.count == 1 && resolved[0] == moscowLocal, "Actual completer resolution merges duplicates")
        let cancelCount = MKLocalSearchCompleter.started.count
        let cancelResolution = Task { await p.fallbackMergedResults(matching: "Jack", localResults: [], excluding: []) }
        await wait { MKLocalSearchCompleter.started.count == cancelCount + 1 }
        let searchCount = MKLocalSearch.started.count
        MKLocalSearchCompleter.started.last!.emit(["One", "Two"])
        await wait { MKLocalSearch.started.count == searchCount + 1 }
        cancelResolution.cancel()
        let cancelled = await cancelResolution.value
        check(cancelled.isEmpty && MKLocalSearch.started.count == searchCount + 1, "Cancellation during resolution prevents next candidate/fallback")
        print("PASS: \(checks) geographic identity, ordering, Added state, row stability, and async checks")
    }
}
