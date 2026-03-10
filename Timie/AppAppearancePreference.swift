import SwiftUI

enum AppAppearancePreference: String, CaseIterable, Codable {
    case system
    case light
    case dark

    static let storageKey = "appearancePreference"

    var displayTitle: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }

    static func from(rawValue: String) -> AppAppearancePreference {
        AppAppearancePreference(rawValue: rawValue) ?? .system
    }

    var preferredColorSchemeOverride: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    func resolvedColorScheme(systemColorScheme: ColorScheme) -> ColorScheme {
        switch self {
        case .system:
            return systemColorScheme
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
