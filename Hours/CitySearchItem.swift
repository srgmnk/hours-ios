import Foundation

struct CitySearchItem: Identifiable, Codable, Hashable {
    enum SpecialReferenceKind: String, Codable, Hashable {
        case utc
        case gmt

        var descriptiveName: String {
            switch self {
            case .utc:
                return "Coordinated Universal Time"
            case .gmt:
                return "Greenwich Mean Time"
            }
        }
    }

    let id: String
    let city: String
    let country: String
    let timeZoneIdentifier: String
    let aliases: [String]
    let canonicalID: String?
    let specialReferenceKind: SpecialReferenceKind?

    init(
        id: String,
        city: String,
        country: String,
        timeZoneIdentifier: String,
        aliases: [String],
        canonicalID: String? = nil,
        specialReferenceKind: SpecialReferenceKind? = nil
    ) {
        self.id = id
        self.city = city
        self.country = country
        self.timeZoneIdentifier = timeZoneIdentifier
        self.aliases = aliases
        self.canonicalID = canonicalID
        self.specialReferenceKind = specialReferenceKind
    }

    var canonicalIdentity: String {
        canonicalID ?? timeZoneIdentifier
    }

    var specialReferenceDescription: String? {
        specialReferenceKind?.descriptiveName
    }

    var asCity: City {
        City(canonicalCity: CanonicalCity(id: canonicalIdentity, name: city, timeZoneID: timeZoneIdentifier))
    }

    func utcOffsetText(referenceDate: Date = Date()) -> String {
        guard let timeZone = TimeZone(identifier: timeZoneIdentifier) else {
            return "UTC"
        }
        return CityTimeFormatter.formatUTCOffset(referenceDate, in: timeZone)
    }

    func rowText(referenceDate: Date = Date()) -> String {
        let leftText = country.isEmpty ? city : "\(city), \(country)"
        return "\(leftText), \(utcOffsetText(referenceDate: referenceDate))"
    }
}
