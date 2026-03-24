//
//  HoursApp.swift
//  created by sergy
//  fortis imaginatio generat casum
//

import SwiftUI

struct ContentView: View {
    @AppStorage(OnboardingStorageKey.hasCompleted) private var hasCompletedOnboarding = false

    var body: some View {
        ZStack {
            TimeDialScreen()
                .allowsHitTesting(hasCompletedOnboarding)

            if !hasCompletedOnboarding {
                OnboardingView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: hasCompletedOnboarding)
    }
}
