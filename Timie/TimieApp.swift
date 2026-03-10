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
            ContentView()
                .environmentObject(cityStore)
        }
    }
}
