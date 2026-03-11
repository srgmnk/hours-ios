import SwiftUI

enum AppThemeVariant {
    case light
    case dark
}

struct DialPillAppearance {
    let foregroundColor: Color
    let glassTintColor: Color?
    let usesInteractiveGlass: Bool
}

struct AppTheme {
    let variant: AppThemeVariant
    let screenBackground: Color
    let surfaceCard: Color
    let surfaceGroupedRow: Color
    let surfaceControl: Color
    let textPrimary: Color
    let textSecondary: Color
    let textSubdued: Color
    let textInverse: Color
    let accent: Color
    let separatorSoft: Color
    let borderSubtle: Color
    let tagAddedBackground: Color
    let tagAddedText: Color
    let tagNeutralBackground: Color
    let tagNeutralText: Color
    let glassFill: Color
    let glassBorder: Color
    let pillNow: DialPillAppearance
    let pillPast: DialPillAppearance
    let pillFuture: DialPillAppearance

    static let light = AppTheme(
        variant: .light,
        screenBackground: Color(red: 238.0 / 255.0, green: 238.0 / 255.0, blue: 238.0 / 255.0),
        surfaceCard: Color(red: 247.0 / 255.0, green: 247.0 / 255.0, blue: 247.0 / 255.0),
        surfaceGroupedRow: Color(red: 247.0 / 255.0, green: 247.0 / 255.0, blue: 247.0 / 255.0),
        surfaceControl: Color.white.opacity(0.8),
        textPrimary: Color(red: 0x22 / 255, green: 0x22 / 255, blue: 0x22 / 255),
        textSecondary: Color.black.opacity(0.2),
        textSubdued: Color.black.opacity(0.15),
        textInverse: .white,
        accent: Color(red: 0xE8 / 255, green: 0x53 / 255, blue: 0x34 / 255),
        separatorSoft: Color.black.opacity(0.05),
        borderSubtle: Color.black.opacity(0.1),
        tagAddedBackground: Color(red: 0xE8 / 255, green: 0xEC / 255, blue: 0xE3 / 255),
        tagAddedText: Color(red: 0x56 / 255, green: 0x82 / 255, blue: 0x22 / 255),
        tagNeutralBackground: .clear,
        tagNeutralText: Color.black.opacity(0.3),
        glassFill: Color.black.opacity(0.07),
        glassBorder: Color.white.opacity(0.2),
        pillNow: DialPillAppearance(
            foregroundColor: Color.black.opacity(0.42),
            glassTintColor: nil,
            usesInteractiveGlass: false
        ),
        pillPast: DialPillAppearance(
            foregroundColor: .white,
            glassTintColor: Color.black.opacity(0.80),
            usesInteractiveGlass: false
        ),
        pillFuture: DialPillAppearance(
            foregroundColor: .white,
            glassTintColor: Color(red: 0xE8 / 255, green: 0x53 / 255, blue: 0x34 / 255),
            usesInteractiveGlass: true
        )
    )

    static let dark = AppTheme(
        variant: .dark,
        screenBackground: Color(red: 17.0 / 255.0, green: 18.0 / 255.0, blue: 20.0 / 255.0),
        surfaceCard: Color(red: 20.0 / 255.0, green: 22.0 / 255.0, blue: 25.0 / 255.0),
        surfaceGroupedRow: Color(red: 20.0 / 255.0, green: 22.0 / 255.0, blue: 25.0 / 255.0),
        surfaceControl: Color.white.opacity(0.04),
        textPrimary: Color.white.opacity(0.85),
        textSecondary: Color.white.opacity(0.3),
        textSubdued: Color.white.opacity(0.15),
        textInverse: .black,
        accent: Color(red: 0xE8 / 255, green: 0x53 / 255, blue: 0x34 / 255),
        separatorSoft: Color.white.opacity(0.08),
        borderSubtle: Color.white.opacity(0.16),
        tagAddedBackground: Color(red: 47.0 / 255.0, green: 53.0 / 255.0, blue: 42.0 / 255.0),
        tagAddedText: Color(red: 182.0 / 255.0, green: 208.0 / 255.0, blue: 145.0 / 255.0),
        tagNeutralBackground: .clear,
        tagNeutralText: Color.white.opacity(0.5),
        glassFill: Color.white.opacity(0.12),
        glassBorder: Color.white.opacity(0.25),
        pillNow: DialPillAppearance(
            foregroundColor: Color.white.opacity(0.80),
            glassTintColor: nil,
            usesInteractiveGlass: false
        ),
        pillPast: DialPillAppearance(
            foregroundColor: Color.black.opacity(0.90),
            glassTintColor: Color.white.opacity(0.88),
            usesInteractiveGlass: false
        ),
        pillFuture: DialPillAppearance(
            foregroundColor: .white,
            glassTintColor: Color(red: 0xE8 / 255, green: 0x53 / 255, blue: 0x34 / 255),
            usesInteractiveGlass: true
        )
    )

    static func forColorScheme(_ colorScheme: ColorScheme) -> AppTheme {
        colorScheme == .dark ? .dark : .light
    }
}

private struct AppThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue = AppTheme.light
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeEnvironmentKey.self] }
        set { self[AppThemeEnvironmentKey.self] = newValue }
    }
}
