import Foundation
import MapKit

@MainActor
final class CitySearchProvider {
    static let shared = CitySearchProvider()

    private final class SearchCompleterBridge: NSObject, MKLocalSearchCompleterDelegate {
        private struct Request {
            let id: UUID
            let completer: MKLocalSearchCompleter
            let continuation: CheckedContinuation<[MKLocalSearchCompletion], Never>
        }

        private var activeRequest: Request?

        func completions(for query: String) async -> [MKLocalSearchCompletion] {
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, !Task.isCancelled else { return [] }

            if let activeRequest {
                finish(requestID: activeRequest.id, with: [])
            }
            let requestID = UUID()

            return await withTaskCancellationHandler {
                await withCheckedContinuation { continuation in
                    guard !Task.isCancelled else {
                        continuation.resume(returning: [])
                        return
                    }
                    // Delegate callbacks identify the completer, not its query.
                    // A separate sender prevents late callbacks from matching a newer request.
                    let completer = MKLocalSearchCompleter()
                    completer.delegate = self
                    completer.resultTypes = [.address]
                    activeRequest = Request(id: requestID, completer: completer, continuation: continuation)
                    completer.queryFragment = trimmed
                }
            } onCancel: {
                Task { @MainActor [weak self] in
                    self?.finish(requestID: requestID, with: [])
                }
            }
        }

        func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
            guard let activeRequest, activeRequest.completer === completer else { return }
            finish(requestID: activeRequest.id, with: completer.results)
        }

        func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: any Error) {
            guard let activeRequest, activeRequest.completer === completer else { return }
            finish(requestID: activeRequest.id, with: [])
        }

        private func finish(requestID: UUID, with results: [MKLocalSearchCompletion]) {
            guard let activeRequest, activeRequest.id == requestID else { return }
            self.activeRequest = nil
            activeRequest.completer.delegate = nil
            activeRequest.completer.cancel()
            activeRequest.continuation.resume(returning: results)
        }
    }

    private struct PopularCitySeed {
        let city: String
        let country: String
        let timeZoneIdentifier: String
    }

    private struct IndexedLocalItem {
        let item: CitySearchItem
        let order: Int
        let normalizedCity: String
        let normalizedCountry: String
        let normalizedAliases: [String]
        let normalizedTimeZone: String
    }

    private struct CompleterResolution {
        let items: [CitySearchItem]
        let hadAddressMatch: Bool
    }

    private let indexedLocalItems: [IndexedLocalItem]
    private let legacyIndexedLocalItems: [IndexedLocalItem]
    private let cityCountryToTimeZone: [String: String]
    private let zeroOffsetReferenceItems: [CitySearchItem]
    private let curatedPopularItems: [CitySearchItem]
    private let completerBridge = SearchCompleterBridge()

    private let localResultLimit = 40
    private let mergedResultLimit = 60
    private let minimumGoodLocalResultCount = 5
    private let completerQueryLengthRange = 2...6
    private let completerResultLimit = 5

    private init(bundle: Bundle = .main) {
        zeroOffsetReferenceItems = Self.zeroOffsetReferenceItemsSeed

        let loadedItems = Self.loadLocalItems(bundle: bundle)
        let specialIDs = Set(zeroOffsetReferenceItems.map(\.id))
        let localItems = zeroOffsetReferenceItems + loadedItems.filter { !specialIDs.contains($0.id) }

        let indexedLocalItemsLocal = localItems.enumerated().map { index, item in
            IndexedLocalItem(
                item: item,
                order: index,
                normalizedCity: Self.normalize(item.city),
                normalizedCountry: Self.normalize(item.country),
                normalizedAliases: item.aliases.map(Self.normalize),
                normalizedTimeZone: Self.normalize(item.timeZoneIdentifier)
            )
        }
        indexedLocalItems = indexedLocalItemsLocal

        // Pre-canonical saved records have only a name and time zone. Expanding
        // the catalog must not give those records a new inferred identity.
        let originalCatalogIDs = Set(OriginalDecorativeCityIDs.catalogIDs)
        legacyIndexedLocalItems = indexedLocalItemsLocal.filter {
            originalCatalogIDs.contains($0.item.id)
        }

        var timeZonesByCityCountry: [String: Set<String>] = [:]
        for indexed in indexedLocalItemsLocal {
            let key = Self.cityCountryKey(city: indexed.normalizedCity, country: indexed.normalizedCountry)
            timeZonesByCityCountry[key, default: []].insert(indexed.item.timeZoneIdentifier)
        }
        // The existing remote conversion can use a catalog time zone only when
        // the city/country key has one unambiguous assignment.
        cityCountryToTimeZone = timeZonesByCityCountry.reduce(into: [:]) { lookup, entry in
            guard entry.value.count == 1 else { return }
            lookup[entry.key] = entry.value.first
        }

        curatedPopularItems = Self.curatedPopularCitySeeds.map { seed in
            if let exact = indexedLocalItemsLocal.first(where: {
                $0.normalizedCity == Self.normalize(seed.city) &&
                $0.normalizedCountry == Self.normalize(seed.country) &&
                $0.normalizedTimeZone == Self.normalize(seed.timeZoneIdentifier)
            }) {
                return exact.item
            }

            if let sameTimeZoneAndCountry = indexedLocalItemsLocal.first(where: {
                $0.normalizedCountry == Self.normalize(seed.country) &&
                $0.normalizedTimeZone == Self.normalize(seed.timeZoneIdentifier)
            }) {
                return sameTimeZoneAndCountry.item
            }

            if let sameTimeZone = indexedLocalItemsLocal.first(where: {
                $0.normalizedTimeZone == Self.normalize(seed.timeZoneIdentifier)
            }) {
                return sameTimeZone.item
            }

            return CitySearchItem(
                id: "popular-\(Self.normalize(seed.city))",
                city: seed.city,
                country: seed.country,
                timeZoneIdentifier: seed.timeZoneIdentifier,
                aliases: []
            )
        }
    }

    func referenceItemsForZeroState() -> [CitySearchItem] {
        zeroOffsetReferenceItems
    }

    func popularCitiesForZeroState() -> [CitySearchItem] {
        curatedPopularItems
    }

    func localResults(
        matching query: String,
        excluding existingTimeZoneIDs: Set<String>
    ) -> [CitySearchItem] {
        let normalizedQuery = Self.normalize(query)
        if normalizedQuery.isEmpty {
            return indexedLocalItems
                .filter { !existingTimeZoneIDs.contains($0.item.timeZoneIdentifier) }
                .prefix(localResultLimit)
                .map(\.item)
        }

        let ranked = indexedLocalItems.compactMap { indexed -> (rank: Int, order: Int, item: CitySearchItem)? in
            guard !existingTimeZoneIDs.contains(indexed.item.timeZoneIdentifier) else { return nil }
            guard let rank = Self.localRank(for: indexed, query: normalizedQuery) else { return nil }
            return (rank, indexed.order, indexed.item)
        }

        let sorted = ranked.sorted { lhs, rhs in
            if lhs.rank != rhs.rank { return lhs.rank < rhs.rank }
            if lhs.order != rhs.order { return lhs.order < rhs.order }
            return lhs.item.city.localizedCaseInsensitiveCompare(rhs.item.city) == .orderedAscending
        }

        return sorted
            .map(\.item)
            .prefix(localResultLimit)
            .map { $0 }
    }

    func shouldFetchFallback(for query: String, localResultCount: Int) -> Bool {
        let normalizedQuery = Self.normalize(query)
        guard normalizedQuery.count >= 2 else { return false }
        return localResultCount == 0 || localResultCount < minimumGoodLocalResultCount
    }

    func fallbackMergedResults(
        matching query: String,
        localResults: [CitySearchItem],
        excluding existingTimeZoneIDs: Set<String>,
        existingCanonicalIDs: Set<String> = []
    ) async -> [CitySearchItem] {
        guard !Task.isCancelled else { return localResults }
        guard shouldFetchFallback(for: query, localResultCount: localResults.count) else {
            return localResults
        }

        let normalizedQuery = Self.normalize(query)
        if completerQueryLengthRange.contains(normalizedQuery.count) {
            let resolution = await resolveCompleterResults(matching: query)
            guard !Task.isCancelled else { return localResults }
            if !resolution.items.isEmpty {
                return mergeResults(
                    localResults: localResults,
                    fallbackResults: resolution.items,
                    excluding: existingTimeZoneIDs,
                    existingCanonicalIDs: existingCanonicalIDs
                )
            }
            // Filtering resolved roads/rivers/POIs must not introduce a second
            // network search. Empty or failed resolution still uses the old fallback.
            if resolution.hadAddressMatch { return localResults }
        }

        guard !Task.isCancelled else { return localResults }
        let fallback = await mapKitFallbackResults(
            matching: query,
            excluding: existingTimeZoneIDs,
            localResults: localResults
        )
        guard !Task.isCancelled else { return localResults }

        return mergeResults(
            localResults: localResults,
            fallbackResults: fallback,
            excluding: existingTimeZoneIDs,
            existingCanonicalIDs: existingCanonicalIDs
        )
    }

    func completerFallbackResults(matching query: String) async -> [CitySearchItem] {
        await resolveCompleterResults(matching: query).items
    }

    private func resolveCompleterResults(matching query: String) async -> CompleterResolution {
        guard !Task.isCancelled else { return CompleterResolution(items: [], hadAddressMatch: false) }
        let completions = await completerBridge.completions(for: query)
        guard !Task.isCancelled else { return CompleterResolution(items: [], hadAddressMatch: false) }

        var resolvedItems: [CitySearchItem] = []
        var hadAddressMatch = false

        for completion in completions.prefix(completerResultLimit) {
            guard !Task.isCancelled else { return CompleterResolution(items: [], hadAddressMatch: hadAddressMatch) }

            let request = MKLocalSearch.Request(completion: completion)
            request.resultTypes = [.address]

            let response: MKLocalSearch.Response
            do {
                response = try await searchResponse(for: request)
            } catch {
                continue
            }

            guard !Task.isCancelled else { return CompleterResolution(items: [], hadAddressMatch: hadAddressMatch) }
            for mapItem in response.mapItems {
                guard let item = citySearchItem(from: mapItem, idPrefix: "completer",
                                               matching: query) else {
                    hadAddressMatch = hadAddressMatch || hasResolvableAddress(mapItem)
                    continue
                }
                hadAddressMatch = true
                resolvedItems.append(item)
                break
            }
        }

        return CompleterResolution(items: resolvedItems, hadAddressMatch: hadAddressMatch)
    }

    func canonicalItemForCurrentLocation(
        city: String,
        country: String,
        timeZoneIdentifier: String
    ) -> CitySearchItem? {
        let normalizedCity = Self.normalize(city)
        let normalizedCountry = Self.normalize(country)

        let exactMatches = indexedLocalItems.filter {
            $0.normalizedCity == normalizedCity &&
            $0.normalizedCountry == normalizedCountry &&
            CityTimeZoneCompatibility.matches($0.item.timeZoneIdentifier, timeZoneIdentifier)
        }
        if !exactMatches.isEmpty {
            return exactMatches.count == 1 ? exactMatches.first?.item : nil
        }

        let aliasMatches = indexedLocalItems.filter {
            $0.normalizedAliases.contains(normalizedCity) &&
            CityTimeZoneCompatibility.matches($0.item.timeZoneIdentifier, timeZoneIdentifier) &&
            $0.normalizedCountry == normalizedCountry
        }
        return aliasMatches.count == 1 ? aliasMatches.first?.item : nil
    }

    func canonicalIdentityForStoredCity(
        city: String,
        timeZoneIdentifier: String
    ) -> String? {
        let normalizedCity = Self.normalize(city)

        let exactMatches = legacyIndexedLocalItems.filter {
            $0.normalizedCity == normalizedCity &&
            CityTimeZoneCompatibility.matches($0.item.timeZoneIdentifier, timeZoneIdentifier) &&
            $0.item.specialReferenceKind == nil
        }
        return exactMatches.count == 1 ? exactMatches.first?.item.canonicalIdentity : nil
    }

    private func mapKitFallbackResults(
        matching query: String,
        excluding existingTimeZoneIDs: Set<String>,
        localResults: [CitySearchItem]
    ) async -> [CitySearchItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !Task.isCancelled else { return [] }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed
        request.resultTypes = [.address]

        let response: MKLocalSearch.Response
        do {
            response = try await searchResponse(for: request)
        } catch {
            return []
        }
        guard !Task.isCancelled else { return [] }

        let normalizedQuery = Self.normalize(trimmed)
        var candidates: [(rank: Int, item: CitySearchItem)] = []

        for mapItem in response.mapItems {
            guard let item = citySearchItem(from: mapItem, idPrefix: "mapkit", matching: query) else { continue }
            let rank = Self.fallbackRank(city: Self.normalize(item.city), country: Self.normalize(item.country), query: normalizedQuery)
            candidates.append((rank, item))
        }

        return candidates
            .sorted { lhs, rhs in
                if lhs.rank != rhs.rank { return lhs.rank < rhs.rank }
                let cityOrder = lhs.item.city.localizedCaseInsensitiveCompare(rhs.item.city)
                if cityOrder != .orderedSame { return cityOrder == .orderedAscending }
                return lhs.item.country.localizedCaseInsensitiveCompare(rhs.item.country) == .orderedAscending
            }
            .map(\.item)
    }

    private func searchResponse(for request: MKLocalSearch.Request) async throws -> MKLocalSearch.Response {
        try Task.checkCancellation()
        let search = MKLocalSearch(request: request)
        return try await withTaskCancellationHandler {
            try Task.checkCancellation()
            let response = try await search.start()
            try Task.checkCancellation()
            return response
        } onCancel: {
            Task { @MainActor in
                search.cancel()
            }
        }
    }

    private func citySearchItem(from mapItem: MKMapItem, idPrefix: String,
                               matching query: String? = nil) -> CitySearchItem? {
        guard CLLocationCoordinate2DIsValid(mapItem.location.coordinate) else { return nil }

        let city = Self.cityName(from: mapItem)
        guard !city.isEmpty else { return nil }
        if let query, !isRelevantCity(city, to: query) { return nil }

        let country = Self.countryName(from: mapItem)
        guard !country.isEmpty else { return nil }

        var timeZoneID = mapItem.timeZone?.identifier
        if timeZoneID == nil {
            let key = Self.cityCountryKey(city: Self.normalize(city), country: Self.normalize(country))
            timeZoneID = cityCountryToTimeZone[key]
        }
        guard let timeZoneIdentifier = timeZoneID, !timeZoneIdentifier.isEmpty else { return nil }

        return CitySearchItem(
            id: "\(idPrefix)-\(Self.normalize(city))|\(Self.normalize(country))|\(timeZoneIdentifier)",
            city: city,
            country: country,
            timeZoneIdentifier: timeZoneIdentifier,
            aliases: [],
            geographicalEvidence: Self.geographicalEvidence(from: mapItem)
        )
    }

    // Request eligibility only: these are the address fields accepted before
    // city-level validation. Discarding such a match must not add a direct request;
    // genuinely malformed/empty resolution retains the existing direct fallback.
    private func hasResolvableAddress(_ mapItem: MKMapItem) -> Bool {
        guard CLLocationCoordinate2DIsValid(mapItem.location.coordinate) else { return false }
        let candidates = [mapItem.addressRepresentations?.cityName,
                          Self.firstAddressComponent(from: mapItem.addressRepresentations?.cityWithContext),
                          Self.firstAddressComponent(from: mapItem.address?.shortAddress),
                          Self.firstAddressComponent(from: mapItem.address?.fullAddress)]
        guard let city = candidates.compactMap({ $0?.trimmingCharacters(in: .whitespacesAndNewlines) })
            .first(where: { !$0.isEmpty && !$0.contains(where: { $0.isNumber }) }) else { return false }
        let country = Self.countryName(from: mapItem)
        guard !country.isEmpty else { return false }
        let key = Self.cityCountryKey(city: Self.normalize(city), country: Self.normalize(country))
        let zone = mapItem.timeZone?.identifier ?? cityCountryToTimeZone[key]
        return !(zone?.isEmpty ?? true)
    }

    private static func geographicalEvidence(from mapItem: MKMapItem) -> CitySearchItem.GeographicalEvidence {
        let coordinate = mapItem.location.coordinate
        let representations = mapItem.addressRepresentations
        return CitySearchItem.GeographicalEvidence(
            placeIdentifier: mapItem.identifier?.rawValue,
            alternatePlaceIdentifiers: mapItem.alternateIdentifiers.map(\.rawValue).sorted(),
            originalName: mapItem.name,
            cityName: representations?.cityName,
            countryCode: representations?.region?.identifier,
            coordinates: CLLocationCoordinate2DIsValid(coordinate)
                ? .init(latitude: coordinate.latitude, longitude: coordinate.longitude) : nil,
            cityWithContext: representations?.cityWithContext,
            cityWithFullContext: representations?.cityWithContext(.full),
            fullAddress: mapItem.address?.fullAddress,
            shortAddress: mapItem.address?.shortAddress,
            pointOfInterestCategory: mapItem.pointOfInterestCategory?.rawValue
        )
    }

    private func mergeResults(
        localResults: [CitySearchItem],
        fallbackResults: [CitySearchItem],
        excluding existingTimeZoneIDs: Set<String>,
        existingCanonicalIDs: Set<String>
    ) -> [CitySearchItem] {
        Array(CitySearchDeduplicator.merge(
            local: localResults,
            remote: fallbackResults,
            catalog: indexedLocalItems.map(\.item),
            existingCanonicalIDs: existingCanonicalIDs
        ).prefix(mergedResultLimit))
    }

    private static func localRank(for indexed: IndexedLocalItem, query: String) -> Int? {
        if indexed.normalizedCity == query { return 0 }
        if indexed.normalizedCity.hasPrefix(query) { return 1 }
        if indexed.normalizedAliases.contains(where: { $0.hasPrefix(query) }) { return 2 }
        if indexed.normalizedCity.contains(query) { return 3 }
        if indexed.normalizedCountry.hasPrefix(query) { return 4 }
        if indexed.normalizedCountry.contains(query) { return 5 }
        if indexed.normalizedAliases.contains(where: { $0.contains(query) }) { return 6 }
        if indexed.normalizedTimeZone.contains(query) { return 7 }
        return nil
    }

    private static func fallbackRank(city: String, country: String, query: String) -> Int {
        if city == query { return 8 }
        if city.hasPrefix(query) { return 9 }
        if city.contains(query) { return 10 }
        if country.hasPrefix(query) { return 11 }
        if country.contains(query) { return 12 }
        return 13
    }

    private static func cityName(from mapItem: MKMapItem) -> String {
        guard mapItem.pointOfInterestCategory == nil else { return "" }
        let placemark = mapItem.placemark
        let name = firstAddressComponent(from: mapItem.name)
        let normalizedName = normalize(name)
        // A locality inherited by a road, numbered address or body of water is
        // not the matched settlement. Water metadata alone can also accompany
        // coastal cities, so reject a named water feature, not every wet anchor.
        let featureNames = [placemark.thoroughfare, placemark.inlandWater, placemark.ocean]
            .compactMap { $0 }.map(normalize).filter { !$0.isEmpty }
        if !normalizedName.isEmpty && featureNames.contains(normalizedName) { return "" }
        if !(placemark.subThoroughfare?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) { return "" }
        if name.isEmpty && !(placemark.thoroughfare?.isEmpty ?? true) { return "" }

        let locality = firstAddressComponent(from: placemark.locality)
        let sublocality = firstAddressComponent(from: placemark.subLocality)
        let settlementNames = Set([locality, sublocality].filter { !$0.isEmpty }.map(normalize))
        let representedCity = firstAddressComponent(from: mapItem.addressRepresentations?.cityName)
        let context = mapItem.addressRepresentations?.cityWithContext(.full) ?? ""
        let contextName = firstAddressComponent(from: context)
        let hasCityContext = !context.isEmpty && !contextName.isEmpty &&
            normalize(context) == normalize(mapItem.address?.fullAddress ?? "")
        let administrativeNames = Set([placemark.administrativeArea, placemark.subAdministrativeArea]
            .compactMap { $0 }.map(normalize).filter { !$0.isEmpty })
        if settlementNames.isEmpty && !normalizedName.isEmpty &&
            administrativeNames.contains(normalizedName) { return "" }

        // A sublocality may be a legitimate village/barangay, while the locality
        // is its containing municipality. Prefer the corroborated matched name.
        if !name.isEmpty {
            if settlementNames.contains(normalizedName) { return name }
            if !settlementNames.isEmpty && normalize(representedCity) == normalizedName { return name }
            if hasCityContext && normalize(contextName) == normalizedName { return name }
            return ""
        }
        // Missing original-name evidence must still have a corroborated locality;
        // administrative areas and free-form address components are not cities.
        if settlementNames.contains(normalize(representedCity)) { return representedCity }
        return ""
    }

    private func isRelevantCity(_ city: String, to query: String) -> Bool {
        let normalizedCity = Self.normalize(city)
        let normalizedQuery = Self.normalize(query)
        var queryNames: Set<String> = [normalizedQuery]
        var hasCatalogMatch = false
        for indexed in indexedLocalItems where indexed.normalizedCity == normalizedQuery ||
            indexed.normalizedAliases.contains(normalizedQuery) {
            hasCatalogMatch = true
            queryNames.insert(indexed.normalizedCity)
            queryNames.formUnion(indexed.normalizedAliases)
        }
        if queryNames.contains(where: { !$0.isEmpty && normalizedCity.contains($0) }) { return true }
        // MapKit does not expose alias metadata for every remote town, and its
        // highlight ranges can be empty for genuine transliterations. Preserve
        // unknown-town linguistic matching after cityName has corroborated the
        // actual matched settlement, rather than inheriting a containing locality.
        return !hasCatalogMatch
    }

    private static func countryName(from mapItem: MKMapItem) -> String {
        let candidates: [String?] = [
            mapItem.addressRepresentations?.regionName,
            lastAddressComponent(from: mapItem.addressRepresentations?.cityWithContext(.full)),
            lastAddressComponent(from: mapItem.address?.fullAddress)
        ]

        for candidate in candidates {
            let value = candidate?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !value.isEmpty else { continue }
            if value.contains(where: { $0.isNumber }) { continue }
            return value
        }

        return ""
    }

    private static func firstAddressComponent(from value: String?) -> String {
        guard let value else { return "" }

        return value
            .replacingOccurrences(of: "\n", with: ",")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first(where: { !$0.isEmpty }) ?? ""
    }

    private static func lastAddressComponent(from value: String?) -> String {
        guard let value else { return "" }

        return value
            .replacingOccurrences(of: "\n", with: ",")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .last(where: { !$0.isEmpty }) ?? ""
    }

    private static func normalize(_ input: String) -> String {
        input
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private static func cityCountryKey(city: String, country: String) -> String {
        "\(city)|\(country)"
    }

    private static func deduplicatedByTimeZone(_ items: [CitySearchItem]) -> [CitySearchItem] {
        var seen = Set<String>()
        var deduplicated: [CitySearchItem] = []

        for item in items {
            guard !seen.contains(item.timeZoneIdentifier) else { continue }
            seen.insert(item.timeZoneIdentifier)
            deduplicated.append(item)
        }

        return deduplicated
    }

    private static func loadLocalItems(bundle: Bundle) -> [CitySearchItem] {
        let candidateURLs: [URL?] = [
            bundle.url(forResource: "cities", withExtension: "json", subdirectory: "Resources"),
            bundle.url(forResource: "cities", withExtension: "json")
        ]

        let decoder = JSONDecoder()

        for candidateURL in candidateURLs {
            guard let url = candidateURL else { continue }
            guard let data = try? Data(contentsOf: url) else { continue }
            guard let decoded = try? decoder.decode([CitySearchItem].self, from: data) else { continue }
            if !decoded.isEmpty {
                return decoded
            }
        }

        return fallbackLocalItems
    }

    private static let fallbackLocalItems: [CitySearchItem] = [
        CitySearchItem(
            id: "fallback-bangkok",
            city: "Bangkok",
            country: "Thailand",
            timeZoneIdentifier: "Asia/Bangkok",
            aliases: ["bkk", "krung thep"]
        ),
        CitySearchItem(
            id: "fallback-perm",
            city: "Perm",
            country: "Russia",
            timeZoneIdentifier: "Asia/Yekaterinburg",
            aliases: ["perm russia", "perm krai"]
        ),
        CitySearchItem(
            id: "fallback-london",
            city: "London",
            country: "United Kingdom",
            timeZoneIdentifier: "Europe/London",
            aliases: ["ldn"]
        ),
        CitySearchItem(
            id: "fallback-new-york",
            city: "New York",
            country: "United States",
            timeZoneIdentifier: "America/New_York",
            aliases: ["nyc", "new york city"]
        ),
        CitySearchItem(
            id: "fallback-tokyo",
            city: "Tokyo",
            country: "Japan",
            timeZoneIdentifier: "Asia/Tokyo",
            aliases: []
        ),
        CitySearchItem(
            id: "fallback-sydney",
            city: "Sydney",
            country: "Australia",
            timeZoneIdentifier: "Australia/Sydney",
            aliases: ["syd"]
        )
    ]

    private static let zeroOffsetReferenceItemsSeed: [CitySearchItem] = [
        CitySearchItem(
            id: "custom.utc",
            city: "UTC",
            country: "",
            timeZoneIdentifier: CustomReferenceOffsetOption.zero(for: .utc).timeZoneIdentifier,
            aliases: ["coordinated universal time", "zulu", "utc+0", "utc 0"],
            canonicalID: CustomReferenceOffsetOption.zero(for: .utc).canonicalID,
            specialReferenceKind: .utc
        ),
        CitySearchItem(
            id: "custom.gmt",
            city: "GMT",
            country: "",
            timeZoneIdentifier: CustomReferenceOffsetOption.zero(for: .gmt).timeZoneIdentifier,
            aliases: ["greenwich mean time", "gmt+0", "gmt 0"],
            canonicalID: CustomReferenceOffsetOption.zero(for: .gmt).canonicalID,
            specialReferenceKind: .gmt
        )
    ]

    private static let curatedPopularCitySeeds: [PopularCitySeed] = [
        PopularCitySeed(city: "Los Angeles", country: "United States", timeZoneIdentifier: "America/Los_Angeles"),
        PopularCitySeed(city: "Denver", country: "United States", timeZoneIdentifier: "America/Denver"),
        PopularCitySeed(city: "Chicago", country: "United States", timeZoneIdentifier: "America/Chicago"),
        PopularCitySeed(city: "New York", country: "United States", timeZoneIdentifier: "America/New_York"),
        PopularCitySeed(city: "São Paulo", country: "Brazil", timeZoneIdentifier: "America/Sao_Paulo"),
        PopularCitySeed(city: "London", country: "United Kingdom", timeZoneIdentifier: "Europe/London"),
        PopularCitySeed(city: "Berlin", country: "Germany", timeZoneIdentifier: "Europe/Berlin"),
        PopularCitySeed(city: "Cairo", country: "Egypt", timeZoneIdentifier: "Africa/Cairo"),
        PopularCitySeed(city: "Dubai", country: "United Arab Emirates", timeZoneIdentifier: "Asia/Dubai"),
        PopularCitySeed(city: "Mumbai", country: "India", timeZoneIdentifier: "Asia/Kolkata"),
        PopularCitySeed(city: "Bangkok", country: "Thailand", timeZoneIdentifier: "Asia/Bangkok"),
        PopularCitySeed(city: "Singapore", country: "Singapore", timeZoneIdentifier: "Asia/Singapore"),
        PopularCitySeed(city: "Tokyo", country: "Japan", timeZoneIdentifier: "Asia/Tokyo"),
        PopularCitySeed(city: "Sydney", country: "Australia", timeZoneIdentifier: "Australia/Sydney"),
        PopularCitySeed(city: "Auckland", country: "New Zealand", timeZoneIdentifier: "Pacific/Auckland")
    ]
}
