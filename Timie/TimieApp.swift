//
//  TimieApp.swift
//  Timie
//
//  Created by Sergy on 27.02.2026.
//

import SwiftUI

@main
struct TimieApp: App {
    @StateObject private var cityStore = CityStore()

    var body: some Scene {
        WindowGroup {
            ThemedRootView()
                .environmentObject(cityStore)
        }
    }
}

private struct ThemedRootView: View {
    @AppStorage(AppAppearancePreference.storageKey) private var appearancePreferenceRawValue = AppAppearancePreference.system.rawValue
    @Environment(\.colorScheme) private var systemColorScheme

    private var appearancePreference: AppAppearancePreference {
        AppAppearancePreference.from(rawValue: appearancePreferenceRawValue)
    }

    private var effectiveColorScheme: ColorScheme {
        appearancePreference.resolvedColorScheme(systemColorScheme: systemColorScheme)
    }

    private var resolvedTheme: AppTheme {
        AppTheme.forColorScheme(effectiveColorScheme)
    }

    var body: some View {
        ContentView()
            .environment(\.appTheme, resolvedTheme)
            .preferredColorScheme(appearancePreference.preferredColorSchemeOverride)
    }
}

