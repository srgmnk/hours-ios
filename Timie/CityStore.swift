import Foundation
import SwiftUI
import Combine

@MainActor
final class CityStore: ObservableObject {
    @Published var cities: [City] = [] {
        didSet {
            guard !isLoading else { return }
            save()
        }
    }

    private let fileManager: FileManager
    private let citiesFileURL: URL
    private var isLoading = false

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        do {
            citiesFileURL = try Self.makeCitiesFileURL(fileManager: fileManager)
        } catch {
            let fallback = fileManager.temporaryDirectory.appendingPathComponent("cities.json", isDirectory: false)
            citiesFileURL = fallback
            log("Failed to resolve Application Support URL. Using fallback \(fallback.path). Error: \(error)")
        }
        load()
    }

    func load() {
        isLoading = true
        defer { isLoading = false }

        do {
            try ensureParentDirectoryExists()
            guard fileManager.fileExists(atPath: citiesFileURL.path) else {
                cities = []
                return
            }
            let data = try Data(contentsOf: citiesFileURL)
            let decoded = try JSONDecoder().decode([City].self, from: data)
            cities = decoded
        } catch {
            log("Failed to load cities from \(citiesFileURL.path). Error: \(error)")
            cities = []
        }
    }

    func save() {
        do {
            try ensureParentDirectoryExists()
            let encoder = JSONEncoder()
            #if DEBUG
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            #endif
            let data = try encoder.encode(cities)
            try data.write(to: citiesFileURL, options: [.atomic])
        } catch {
            log("Failed to save cities to \(citiesFileURL.path). Error: \(error)")
        }
    }

    private static func makeCitiesFileURL(fileManager: FileManager) throws -> URL {
        let applicationSupportDirectory = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return applicationSupportDirectory.appendingPathComponent("cities.json", isDirectory: false)
    }

    private func ensureParentDirectoryExists() throws {
        let directory = citiesFileURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }

    private func log(_ message: String) {
        #if DEBUG
        print("[CityStore] \(message)")
        #endif
    }
}
