import Foundation

enum AppTimeFormatPreference: String, CaseIterable, Codable {
    case system
    case twentyFourHour
    case twelveHour

    static let storageKey = "timeFormatPreference"

    var displayTitle: String {
        switch self {
        case .system:
            return "System"
        case .twentyFourHour:
            return "24-Hour"
        case .twelveHour:
            return "12-Hour"
        }
    }

    static func from(rawValue: String) -> AppTimeFormatPreference {
        AppTimeFormatPreference(rawValue: rawValue) ?? .system
    }

    func resolvedUses12HourClock(systemUses12HourClock: Bool) -> Bool {
        switch self {
        case .system:
            return systemUses12HourClock
        case .twentyFourHour:
            return false
        case .twelveHour:
            return true
        }
    }
}
