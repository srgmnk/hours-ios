import Foundation

enum LegalDocument: String, Identifiable {
    case privacy
    case terms
    case dataAttribution

    var id: String { rawValue }

    var title: String {
        switch self {
        case .privacy:
            return "Privacy Policy"
        case .terms:
            return "Terms of Use"
        case .dataAttribution:
            return "Data Attribution"
        }
    }

    func url(for theme: AppTheme) -> URL? {
        guard let baseURLString else { return nil }
        var components = URLComponents(string: baseURLString)!
        components.queryItems = [
            URLQueryItem(name: "theme", value: themeQueryValue(for: theme))
        ]
        return components.url!
    }

    private var baseURLString: String? {
        switch self {
        case .privacy:
            return "https://sergy.xyz/hours/privacy/"
        case .terms:
            return "https://sergy.xyz/hours/terms/"
        case .dataAttribution:
            return nil
        }
    }

    private func themeQueryValue(for theme: AppTheme) -> String {
        switch theme.variant {
        case .dark:
            return "dark"
        case .light:
            return "light"
        }
    }
}
