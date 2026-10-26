import Foundation
import CryptoKit

/// Conservative result equivalence. Names, countries, time zones, and legacy canonical IDs
/// are never sufficient to merge two unverified remote locations.
enum CitySearchDeduplicator {
    private struct Group {
        var item: CitySearchItem
        var keys: Set<String>
        var isCatalog: Bool
    }

    // Reviewed city-level MapKit responses, 2026-10-26.
    // Exact returned anchors, not radius-based municipality boundaries. Unverified catalog
    // cities deliberately have no entry. A changed response remains separate for review.
    private static let catalogAnchors: [String: String] = [
        "bangkok-th": "TH|13.753786|100.498525",
        "moscow-ru": "RU|55.758664|37.619292",
        "paris-fr": "FR|48.856788|2.351077"
    ]

    static func merge(
        local: [CitySearchItem],
        remote: [CitySearchItem],
        catalog: [CitySearchItem],
        existingCanonicalIDs: Set<String> = []
    ) -> [CitySearchItem] {
        let catalogByID = Dictionary(catalog.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var groups: [Group] = []

        for source in local + remote {
            var item = source
            var isCatalog = source.geographicalEvidence == nil && catalogByID[source.id] == source
            var keys = evidenceKeys(source.geographicalEvidence)
            if isCatalog {
                keys.insert("catalog:" + source.id)
            } else if let canonical = verifiedCatalogItem(for: source, catalog: catalogByID) {
                item = copy(canonical, evidence: source.geographicalEvidence)
                isCatalog = true
                keys.insert("catalog:" + canonical.id)
            } else if !keys.isEmpty {
                // Keep geographic identity distinct from the old name/country/time-zone ID.
                // Existing city: IDs survive CityStore's current migration unchanged.
                let orderedKeys = keys.sorted {
                    if $0.hasPrefix("place:") != $1.hasPrefix("place:") {
                        return $0.hasPrefix("place:")
                    }
                    return $0 < $1
                }
                let candidates = orderedKeys.map(canonicalID)
                let identity = candidates.first(where: existingCanonicalIDs.contains)
                    ?? candidates.first!
                item = copy(source, canonicalID: identity, evidence: source.geographicalEvidence)
            }

            // Empty evidence is ambiguity, not permission to collapse matching text or IDs.
            let matches = groups.indices.filter { !keys.isDisjoint(with: groups[$0].keys) }
            guard let first = matches.first else {
                groups.append(Group(item: item, keys: keys, isCatalog: isCatalog))
                continue
            }

            // Alternate identifiers can join groups. Keep the earliest result position and
            // collect every key so a later callback cannot reintroduce an equivalent record.
            var group = groups[first]
            for index in matches.dropFirst() {
                group = combined(group, groups[index], existingCanonicalIDs: existingCanonicalIDs)
            }
            group = combined(group, Group(item: item, keys: keys, isCatalog: isCatalog),
                             existingCanonicalIDs: existingCanonicalIDs)
            groups[first] = group
            for index in matches.dropFirst().reversed() { groups.remove(at: index) }
        }
        return groups.map(\.item)
    }

    private static func verifiedCatalogItem(
        for item: CitySearchItem, catalog: [String: CitySearchItem]
    ) -> CitySearchItem? {
        guard let evidence = item.geographicalEvidence,
              let anchor = coordinateAnchor(evidence),
              let originalName = evidence.originalName,
              let cityName = evidence.cityName,
              let address = evidence.fullAddress,
              let context = evidence.cityWithFullContext,
              !address.isEmpty, normalize(address) == normalize(context),
              evidence.pointOfInterestCategory == nil else { return nil }
        return catalogAnchors.keys.sorted().compactMap { id -> CitySearchItem? in
            guard catalogAnchors[id] == anchor, let local = catalog[id],
                  local.timeZoneIdentifier == item.timeZoneIdentifier else { return nil }
            let names = Set(([local.city] + local.aliases).map(normalize))
            guard names.contains(normalize(originalName)), names.contains(normalize(cityName)) else { return nil }
            return local
        }.first
    }

    private static func evidenceKeys(_ evidence: CitySearchItem.GeographicalEvidence?) -> Set<String> {
        guard let evidence else { return [] }
        var keys = Set(([evidence.placeIdentifier].compactMap { $0 } + (evidence.alternatePlaceIdentifiers ?? []))
            .filter { !$0.isEmpty }.map { "place:" + $0 })
        if let anchor = coordinateAnchor(evidence),
           let name = evidence.originalName, !name.isEmpty,
           let city = evidence.cityName, !city.isEmpty,
           let context = evidence.cityWithFullContext, !context.isEmpty,
           let address = evidence.fullAddress, !address.isEmpty {
            // Match the same resolved representation, not just nearby points or a city label
            // inherited by unrelated street addresses. Length framing avoids delimiter collisions.
            let fields = [anchor, normalize(name), normalize(city), normalize(context), normalize(address)]
            keys.insert("location:" + fields.map { "\($0.utf8.count):\($0)" }.joined())
        }
        return keys
    }

    private static func coordinateAnchor(_ evidence: CitySearchItem.GeographicalEvidence) -> String? {
        guard let code = evidence.countryCode, !code.isEmpty, let c = evidence.coordinates,
              c.latitude.isFinite, c.longitude.isFinite,
              abs(c.latitude) <= 90, abs(c.longitude) <= 180 else { return nil }
        return String(format: "%@|%.6f|%.6f", locale: Locale(identifier: "en_US_POSIX"),
                      code.uppercased(), c.latitude, c.longitude)
    }

    private nonisolated static func canonicalID(_ key: String) -> String {
        let digest = SHA256.hash(data: Data(key.utf8)).map { String(format: "%02x", $0) }.joined()
        return "city:mapkit:" + digest
    }

    private static func combined(_ first: Group, _ next: Group, existingCanonicalIDs: Set<String>) -> Group {
        let preferred: Group
        let other: Group
        if (next.isCatalog && !first.isCatalog) ||
            (next.isCatalog == first.isCatalog &&
             existingCanonicalIDs.contains(next.item.canonicalIdentity) &&
             !existingCanonicalIDs.contains(first.item.canonicalIdentity)) {
            preferred = next; other = first
        } else {
            preferred = first; other = next
        }
        return Group(item: copy(preferred.item, evidence: mergedEvidence(preferred.item.geographicalEvidence,
                                                                         other.item.geographicalEvidence)),
                     keys: first.keys.union(next.keys), isCatalog: preferred.isCatalog)
    }

    private static func mergedEvidence(_ a: CitySearchItem.GeographicalEvidence?,
                                       _ b: CitySearchItem.GeographicalEvidence?) -> CitySearchItem.GeographicalEvidence? {
        guard let a else { return b }
        guard let b else { return a }
        var identifiers = Set(a.alternatePlaceIdentifiers ?? [])
        identifiers.formUnion(b.alternatePlaceIdentifiers ?? [])
        if let id = a.placeIdentifier { identifiers.insert(id) }
        if let id = b.placeIdentifier { identifiers.insert(id) }
        let placeIdentifier = a.placeIdentifier ?? b.placeIdentifier
        let originalName = a.originalName ?? b.originalName
        let cityName = a.cityName ?? b.cityName
        let countryCode = a.countryCode ?? b.countryCode
        let coordinates = a.coordinates ?? b.coordinates
        let cityWithContext = a.cityWithContext ?? b.cityWithContext
        let cityWithFullContext = a.cityWithFullContext ?? b.cityWithFullContext
        let fullAddress = a.fullAddress ?? b.fullAddress
        let shortAddress = a.shortAddress ?? b.shortAddress
        let pointOfInterestCategory = a.pointOfInterestCategory ?? b.pointOfInterestCategory
        return CitySearchItem.GeographicalEvidence(
            placeIdentifier: placeIdentifier, alternatePlaceIdentifiers: identifiers.sorted(),
            originalName: originalName, cityName: cityName, countryCode: countryCode,
            coordinates: coordinates, cityWithContext: cityWithContext,
            cityWithFullContext: cityWithFullContext, fullAddress: fullAddress,
            shortAddress: shortAddress, pointOfInterestCategory: pointOfInterestCategory)
    }

    private static func copy(_ item: CitySearchItem, canonicalID: String? = nil,
                             evidence: CitySearchItem.GeographicalEvidence?) -> CitySearchItem {
        CitySearchItem(id: item.id, city: item.city, country: item.country,
                       timeZoneIdentifier: item.timeZoneIdentifier, aliases: item.aliases,
                       canonicalID: canonicalID ?? item.canonicalID, specialReferenceKind: item.specialReferenceKind,
                       geographicalEvidence: evidence)
    }

    private nonisolated static func normalize(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
