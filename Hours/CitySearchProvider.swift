import Foundation
import MapKit

@MainActor
final class CitySearchProvider {
    static let shared = CitySearchProvider()

    private final class SearchCompleterBridge: NSObject, MKLocalSearchCompleterDelegate {
        private let completer = MKLocalSearchCompleter()
        private var continuation: CheckedContinuation<[MKLocalSearchCompletion], Never>?

        override init() {
            super.init()
            completer.delegate = self
            completer.resultTypes = [.address]
        }

        func completions(for query: String) async -> [MKLocalSearchCompletion] {
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return [] }

            completer.cancel()
            finish(with: [])

            return await withTaskCancellationHandler {
                await withCheckedContinuation { continuation in
                    self.continuation = continuation
                    completer.queryFragment = trimmed
                }
            } onCancel: {
                Task { @MainActor [weak self] in
                    self?.completer.cancel()
                    self?.finish(with: [])
                }
            }
        }

        func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
            finish(with: completer.results)
        }

        func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: any Error) {
            finish(with: [])
        }

        private func finish(with results: [MKLocalSearchCompletion]) {
            guard let continuation else { return }
            self.continuation = nil
            continuation.resume(returning: results)
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

    private let indexedLocalItems: [IndexedLocalItem]
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

        var lookup: [String: String] = [:]
        for indexed in indexedLocalItemsLocal {
            let key = Self.cityCountryKey(city: indexed.normalizedCity, country: indexed.normalizedCountry)
            lookup[key] = indexed.item.timeZoneIdentifier
        }
        cityCountryToTimeZone = lookup

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
        excluding existingTimeZoneIDs: Set<String>
    ) async -> [CitySearchItem] {
        guard shouldFetchFallback(for: query, localResultCount: localResults.count) else {
            return localResults
        }

        let normalizedQuery = Self.normalize(query)
        if completerQueryLengthRange.contains(normalizedQuery.count) {
            let completerResults = await completerFallbackResults(matching: query)
            if !completerResults.isEmpty {
                return mergeResults(
                    localResults: localResults,
                    fallbackResults: completerResults,
                    excluding: existingTimeZoneIDs
                )
            }
        }

        let fallback = await mapKitFallbackResults(
            matching: query,
            excluding: existingTimeZoneIDs,
            localResults: localResults
        )

        return mergeResults(
            localResults: localResults,
            fallbackResults: fallback,
            excluding: existingTimeZoneIDs
        )
    }

    func completerFallbackResults(matching query: String) async -> [CitySearchItem] {
        let completions = await completerBridge.completions(for: query)
        guard !Task.isCancelled else { return [] }

        var resolvedItems: [CitySearchItem] = []

        for completion in completions.prefix(completerResultLimit) {
            guard !Task.isCancelled else { return [] }

            let request = MKLocalSearch.Request(completion: completion)
            request.resultTypes = [.address]

            let response: MKLocalSearch.Response
            do {
                response = try await MKLocalSearch(request: request).start()
            } catch {
                continue
            }

            guard !Task.isCancelled else { return [] }

            for mapItem in response.mapItems {
                guard let item = citySearchItem(from: mapItem, idPrefix: "completer") else { continue }
                resolvedItems.append(item)
                break
            }
        }

        return resolvedItems
    }

    func canonicalItemForCurrentLocation(
        city: String,
        country: String,
        timeZoneIdentifier: String
    ) -> CitySearchItem? {
        let normalizedCity = Self.normalize(city)
        let normalizedCountry = Self.normalize(country)
        let normalizedTimeZone = Self.normalize(timeZoneIdentifier)

        if let exact = indexedLocalItems.first(where: {
            $0.normalizedCity == normalizedCity &&
            $0.normalizedCountry == normalizedCountry &&
            $0.normalizedTimeZone == normalizedTimeZone
        }) {
            return exact.item
        }

        if let cityAndCountry = indexedLocalItems.first(where: {
            $0.normalizedCity == normalizedCity &&
            $0.normalizedCountry == normalizedCountry
        }) {
            return cityAndCountry.item
        }

        if let timeZoneAndCountry = indexedLocalItems.first(where: {
            $0.normalizedTimeZone == normalizedTimeZone &&
            $0.normalizedCountry == normalizedCountry
        }) {
            return timeZoneAndCountry.item
        }

        if let timeZoneOnly = indexedLocalItems.first(where: {
            $0.normalizedTimeZone == normalizedTimeZone
        }) {
            return timeZoneOnly.item
        }

        return nil
    }

    func canonicalIdentityForStoredCity(
        city: String,
        timeZoneIdentifier: String
    ) -> String? {
        let normalizedCity = Self.normalize(city)
        let normalizedTimeZone = Self.normalize(timeZoneIdentifier)

        let exactMatches = indexedLocalItems.filter {
            $0.normalizedCity == normalizedCity &&
            $0.normalizedTimeZone == normalizedTimeZone &&
            $0.item.specialReferenceKind == nil
        }
        if let exact = exactMatches.first {
            return exact.item.canonicalIdentity
        }

        let cityOnlyMatches = indexedLocalItems.filter {
            $0.normalizedCity == normalizedCity &&
            $0.item.specialReferenceKind == nil
        }
        if cityOnlyMatches.count == 1, let match = cityOnlyMatches.first {
            return match.item.canonicalIdentity
        }

        return nil
    }

    private func mapKitFallbackResults(
        matching query: String,
        excluding existingTimeZoneIDs: Set<String>,
        localResults: [CitySearchItem]
    ) async -> [CitySearchItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed
        request.resultTypes = [.address]

        let response: MKLocalSearch.Response
        do {
            response = try await MKLocalSearch(request: request).start()
        } catch {
            return []
        }

        let normalizedQuery = Self.normalize(trimmed)
        var candidates: [(rank: Int, item: CitySearchItem)] = []

        for mapItem in response.mapItems {
            guard CLLocationCoordinate2DIsValid(mapItem.location.coordinate) else { continue }

            let city = Self.cityName(from: mapItem)
            guard !city.isEmpty else { continue }

            let country = Self.countryName(from: mapItem)
            guard !country.isEmpty else { continue }

            var timeZoneID = mapItem.timeZone?.identifier
            if timeZoneID == nil {
                let key = Self.cityCountryKey(city: Self.normalize(city), country: Self.normalize(country))
                timeZoneID = cityCountryToTimeZone[key]
            }
            guard let timeZoneIdentifier = timeZoneID, !timeZoneIdentifier.isEmpty else { continue }

            let item = CitySearchItem(
                id: "mapkit-\(Self.normalize(city))|\(Self.normalize(country))|\(timeZoneIdentifier)",
                city: city,
                country: country,
                timeZoneIdentifier: timeZoneIdentifier,
                aliases: []
            )

            let rank = Self.fallbackRank(city: Self.normalize(city), country: Self.normalize(country), query: normalizedQuery)
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

    private func citySearchItem(from mapItem: MKMapItem, idPrefix: String) -> CitySearchItem? {
        guard CLLocationCoordinate2DIsValid(mapItem.location.coordinate) else { return nil }

        let city = Self.cityName(from: mapItem)
        guard !city.isEmpty else { return nil }

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
            aliases: []
        )
    }

    private func mergeResults(
        localResults: [CitySearchItem],
        fallbackResults: [CitySearchItem],
        excluding existingTimeZoneIDs: Set<String>
    ) -> [CitySearchItem] {
        var merged: [CitySearchItem] = []

        func appendIfNeeded(_ item: CitySearchItem) {
            merged.append(item)
        }

        for item in localResults {
            appendIfNeeded(item)
        }
        for item in fallbackResults {
            appendIfNeeded(item)
        }

        return Array(merged.prefix(mergedResultLimit))
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
        let candidates: [String?] = [
            mapItem.addressRepresentations?.cityName,
            firstAddressComponent(from: mapItem.addressRepresentations?.cityWithContext),
            firstAddressComponent(from: mapItem.address?.shortAddress),
            firstAddressComponent(from: mapItem.address?.fullAddress)
        ]

        for candidate in candidates {
            let value = candidate?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !value.isEmpty else { continue }
            if value.contains(where: { $0.isNumber }) { continue }
            return value
        }

        return ""
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
