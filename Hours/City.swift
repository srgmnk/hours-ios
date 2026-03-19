import Foundation

enum CustomReferenceFamily: String, Codable, Hashable {
    case utc
    case gmt

    var code: String {
        rawValue.uppercased()
    }

    var descriptiveName: String {
        switch self {
        case .utc:
            return "Coordinated Universal Time"
        case .gmt:
            return "Greenwich Mean Time"
        }
    }
}

struct CustomReferenceOffsetOption: Identifiable, Hashable {
    let family: CustomReferenceFamily
    let minutesFromGMT: Int

    var id: String { canonicalID }

    var secondsFromGMT: Int {
        minutesFromGMT * 60
    }

    var canonicalID: String {
        "custom.\(family.rawValue).offset.\(asciiOffsetComponent)"
    }

    var timeZoneIdentifier: String {
        canonicalID
    }

    var selectionLabel: String {
        "\(family.code)\(displayOffsetComponent)"
    }

    var cityName: String {
        selectionLabel
    }

    static func zero(for family: CustomReferenceFamily) -> CustomReferenceOffsetOption {
        CustomReferenceOffsetOption(family: family, minutesFromGMT: 0)
    }

    static func supportedOptions(for family: CustomReferenceFamily) -> [CustomReferenceOffsetOption] {
        supportedMinutesFromGMT.map { minutes in
            CustomReferenceOffsetOption(family: family, minutesFromGMT: minutes)
        }
    }

    static func from(canonicalID: String) -> CustomReferenceOffsetOption? {
        parse(identifier: canonicalID)
    }

    static func from(timeZoneIdentifier: String) -> CustomReferenceOffsetOption? {
        parse(identifier: timeZoneIdentifier)
    }

    private var asciiOffsetComponent: String {
        let absoluteMinutes = abs(minutesFromGMT)
        let hours = absoluteMinutes / 60
        let minutes = absoluteMinutes % 60
        let sign = minutesFromGMT >= 0 ? "+" : "-"
        return String(format: "%@%02d:%02d", sign, hours, minutes)
    }

    private var displayOffsetComponent: String {
        let absoluteMinutes = abs(minutesFromGMT)
        let hours = absoluteMinutes / 60
        let minutes = absoluteMinutes % 60

        if minutesFromGMT == 0 {
            return "−0"
        }

        let sign = minutesFromGMT > 0 ? "+" : "−"

        if minutes == 0 {
            return "\(sign)\(hours)"
        }

        return "\(sign)\(hours):" + String(format: "%02d", minutes)
    }

    private static let supportedMinutesFromGMT: [Int] = [
        -12 * 60,
        -11 * 60,
        -10 * 60,
        -9 * 60,
        -(9 * 60 + 30),
        -8 * 60,
        -7 * 60,
        -6 * 60,
        -5 * 60,
        -4 * 60,
        -(3 * 60 + 30),
        -3 * 60,
        -2 * 60,
        -1 * 60,
        0,
        1 * 60,
        2 * 60,
        3 * 60,
        3 * 60 + 30,
        4 * 60,
        4 * 60 + 30,
        5 * 60,
        5 * 60 + 30,
        5 * 60 + 45,
        6 * 60,
        6 * 60 + 30,
        7 * 60,
        8 * 60,
        8 * 60 + 45,
        9 * 60,
        9 * 60 + 30,
        10 * 60,
        10 * 60 + 30,
        11 * 60,
        12 * 60,
        12 * 60 + 45,
        13 * 60,
        14 * 60
    ]

    private static func parse(identifier: String) -> CustomReferenceOffsetOption? {
        let lowercased = identifier.lowercased()

        if lowercased == "custom.utc" || lowercased == "etc/utc" || lowercased == "utc" {
            return zero(for: .utc)
        }
        if lowercased == "custom.gmt" || lowercased == "gmt" {
            return zero(for: .gmt)
        }

        for family in [CustomReferenceFamily.utc, .gmt] {
            let prefix = "custom.\(family.rawValue).offset."
            guard lowercased.hasPrefix(prefix) else { continue }

            let offsetComponent = String(lowercased.dropFirst(prefix.count))
            guard let minutes = parseMinutes(offsetComponent) else { return nil }
            return CustomReferenceOffsetOption(family: family, minutesFromGMT: minutes)
        }

        return nil
    }

    private static func parseMinutes(_ offsetComponent: String) -> Int? {
        guard offsetComponent.count == 6 else { return nil }
        guard let sign = offsetComponent.first, sign == "+" || sign == "-" else { return nil }

        let raw = String(offsetComponent.dropFirst())
        let pieces = raw.split(separator: ":")
        guard pieces.count == 2,
              let hours = Int(pieces[0]),
              let minutes = Int(pieces[1]) else {
            return nil
        }

        let totalMinutes = hours * 60 + minutes
        return sign == "-" ? -totalMinutes : totalMinutes
    }
}

extension TimeZone {
    static func hoursResolved(identifier: String) -> TimeZone? {
        if let customReference = CustomReferenceOffsetOption.from(timeZoneIdentifier: identifier) {
            return TimeZone(secondsFromGMT: customReference.secondsFromGMT)
        }

        return TimeZone(identifier: identifier)
    }
}

struct CanonicalCity: Identifiable, Equatable, Hashable, Codable {
    let id: String
    let name: String
    let timeZoneID: String

    var timeZone: TimeZone {
        TimeZone.hoursResolved(identifier: timeZoneID) ?? .current
    }

    init(id: String? = nil, name: String, timeZoneID: String) {
        self.id = id ?? CitySearchItem.makeCanonicalIdentity(
            city: name,
            country: "",
            timeZoneIdentifier: timeZoneID
        )
        self.name = name
        self.timeZoneID = timeZoneID
    }
}

struct City: Identifiable, Equatable, Codable {
    static let current = City(name: "Bangkok", timeZoneID: "Asia/Bangkok")

    let canonicalCity: CanonicalCity
    var customDisplayName: String?

    var id: String { canonicalCity.id }
    var name: String { canonicalCity.name }
    var timeZoneID: String { canonicalCity.timeZoneID }

    var displayName: String {
        let trimmedCustomName = customDisplayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedCustomName.isEmpty ? canonicalCity.name : trimmedCustomName
    }

    var timeZone: TimeZone {
        canonicalCity.timeZone
    }

    init(canonicalCity: CanonicalCity, customDisplayName: String? = nil) {
        self.canonicalCity = canonicalCity
        self.customDisplayName = customDisplayName
    }

    init(name: String, timeZoneID: String, customDisplayName: String? = nil, canonicalID: String? = nil) {
        self.init(
            canonicalCity: CanonicalCity(id: canonicalID, name: name, timeZoneID: timeZoneID),
            customDisplayName: customDisplayName
        )
    }

    // Backward-compatible alias for pre-refactor call sites.
    init(name: String, timeZoneID: String, customName: String?) {
        self.init(name: name, timeZoneID: timeZoneID, customDisplayName: customName, canonicalID: nil)
    }

    // Backward-compatible alias for pre-refactor call sites.
    var customName: String? {
        get { customDisplayName }
        set { customDisplayName = newValue }
    }
}
