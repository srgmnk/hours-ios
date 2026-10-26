import Foundation
import SwiftUI
import Combine
#if canImport(WidgetKit)
import WidgetKit
#endif

@MainActor
final class CityStore: ObservableObject {
    enum PersistenceStatus {
        case loading
        case loaded
        case fileAbsent
        case loadFailed(Error)
        case unavailable(Error)
        case saveFailed(Error)
    }

    // Injectable I/O keeps fault tests away from real app and widget storage.
    struct Storage {
        var read: (URL) throws -> Data = { try Data(contentsOf: $0) }
        var write: (Data, URL) throws -> Void = { try $0.write(to: $1, options: [.atomic]) }
        var sharedDefaults: (String) -> UserDefaults? = { UserDefaults(suiteName: $0) }
        var reloadWidgets: () -> Void = {
            #if canImport(WidgetKit)
            WidgetCenter.shared.reloadAllTimelines()
            #endif
        }
    }

    private enum WidgetSyncFailure: Error {
        case unavailableContainer
        case unavailableDefaults
    }

    private struct WidgetCityRecord: Codable {
        let id: String
        let canonicalName: String
        let customDisplayName: String?
        let timeZoneIdentifier: String
    }

    private enum WidgetSharedStorage {
        static let appGroupIdentifier = "group.ai.srgmnk.hours"
        static let citiesKey = "widget.savedCities"
        static let citiesFileName = "widget-saved-cities.json"
    }

    @Published var cities: [City] = [] {
        didSet {
            guard !isLoading else { return }
            save()
        }
    }

    @Published private(set) var persistenceStatus: PersistenceStatus = .loading
    @Published private(set) var widgetSyncError: Error?

    private let fileManager: FileManager
    private let storage: Storage
    private var citiesFileURL: URL?
    private var isLoading = false
    // Once a file was read (or could not be read), disappearance is not first launch.
    private var requiresExistingFile = false

    init(fileManager: FileManager = .default, storage: Storage? = nil) {
        self.fileManager = fileManager
        self.storage = storage ?? Storage()
        load()
    }

    func load() {
        isLoading = true
        persistenceStatus = .loading
        defer { isLoading = false }

        do {
            citiesFileURL = try Self.makeCitiesFileURL(fileManager: fileManager)
        } catch {
            citiesFileURL = nil
            persistenceStatus = .unavailable(error)
            log("Failed to resolve Application Support URL. Error: \(error)")
            return
        }
        guard let citiesFileURL else { return }

        let data: Data
        do {
            data = try storage.read(citiesFileURL)
        } catch {
            let readError = error as NSError
            if !requiresExistingFile,
               readError.domain == NSCocoaErrorDomain,
               readError.code == NSFileReadNoSuchFileError {
                cities = []
                persistenceStatus = .fileAbsent
            } else {
                requiresExistingFile = true
                persistenceStatus = .loadFailed(error)
                log("Failed to read cities from \(citiesFileURL.path). Error: \(error)")
            }
            return
        }

        requiresExistingFile = true
        do {
            let decoded = try JSONDecoder().decode([City].self, from: data)
            let migration = migrateCanonicalIdentitiesIfNeeded(decoded)
            cities = migration.cities
            persistenceStatus = .loaded
            if migration.didMigrate {
                save()
            } else {
                syncWidgetSharedCities(migration.cities)
            }
        } catch {
            persistenceStatus = .loadFailed(error)
            log("Failed to load cities from \(citiesFileURL.path). Error: \(error)")
        }
    }

    // The result reports primary-file durability; widget failures are separate.
    @discardableResult
    func save() -> Bool {
        switch persistenceStatus {
        case .loaded, .fileAbsent: break
        default: return false
        }
        guard let citiesFileURL else { return false }
        let committedCities = cities
        do {
            try ensureParentDirectoryExists(for: citiesFileURL)
            let encoder = JSONEncoder()
            #if DEBUG
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            #endif
            let data = try encoder.encode(committedCities)
            try storage.write(data, citiesFileURL)
            requiresExistingFile = true
            persistenceStatus = .loaded
            syncWidgetSharedCities(committedCities)
            return true
        } catch {
            persistenceStatus = .saveFailed(error)
            log("Failed to save cities to \(citiesFileURL.path). Error: \(error)")
            return false
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

    private func ensureParentDirectoryExists(for fileURL: URL) throws {
        try fileManager.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    }

    private func migrateCanonicalIdentitiesIfNeeded(_ cities: [City]) -> (cities: [City], didMigrate: Bool) {
        var didMigrate = false
        var migratedCities: [City] = []
        migratedCities.reserveCapacity(cities.count)

        for city in cities {
            let migratedID = migratedCanonicalID(for: city)
            if migratedID != city.id {
                didMigrate = true
            }

            let migratedCity = City(
                canonicalCity: CanonicalCity(
                    id: migratedID,
                    name: city.name,
                    timeZoneID: city.timeZoneID
                ),
                customDisplayName: city.customDisplayName
            )
            migratedCities.append(migratedCity)
        }

        return (migratedCities, didMigrate)
    }

    private func migratedCanonicalID(for city: City) -> String {
        if let customReferenceID = customReferenceCanonicalIDIfNeeded(for: city) {
            return customReferenceID
        }

        if city.id.hasPrefix("city:") {
            return city.id
        }

        if let providerCanonicalID = CitySearchProvider.shared.canonicalIdentityForStoredCity(
            city: city.name,
            timeZoneIdentifier: city.timeZoneID
        ) {
            return providerCanonicalID
        }

        return CitySearchItem.makeCanonicalIdentity(
            city: city.name,
            country: "",
            timeZoneIdentifier: city.timeZoneID
        )
    }

    private func customReferenceCanonicalIDIfNeeded(for city: City) -> String? {
        if let customReferenceID = CustomReferenceOffsetOption.from(canonicalID: city.id)?.canonicalID {
            return customReferenceID
        }

        if let customReferenceID = CustomReferenceOffsetOption.from(timeZoneIdentifier: city.timeZoneID)?.canonicalID {
            return customReferenceID
        }

        return nil
    }

    private func log(_ message: String) {
        #if DEBUG
        print("[CityStore] \(message)")
        #endif
    }

    private func syncWidgetSharedCities(_ cities: [City]) {
        let sharedCities = cities.map {
            WidgetCityRecord(
                id: $0.id,
                canonicalName: $0.name,
                customDisplayName: $0.customDisplayName,
                timeZoneIdentifier: $0.timeZoneID
            )
        }

        do {
            let encoder = JSONEncoder()
            #if DEBUG
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            #endif
            let data = try encoder.encode(sharedCities)
            var syncError: Error?
            var didUpdateSnapshot = false
            if let sharedDirectoryURL = fileManager.containerURL(
                forSecurityApplicationGroupIdentifier: WidgetSharedStorage.appGroupIdentifier
            ) {
                let sharedFileURL = sharedDirectoryURL.appendingPathComponent(
                    WidgetSharedStorage.citiesFileName,
                    isDirectory: false
                )
                try storage.write(data, sharedFileURL)
                didUpdateSnapshot = true
            } else {
                syncError = WidgetSyncFailure.unavailableContainer
                log("Failed to open shared container for app group \(WidgetSharedStorage.appGroupIdentifier)")
            }

            if let sharedDefaults = storage.sharedDefaults(WidgetSharedStorage.appGroupIdentifier) {
                sharedDefaults.set(data, forKey: WidgetSharedStorage.citiesKey)
                didUpdateSnapshot = true
            } else {
                syncError = syncError ?? WidgetSyncFailure.unavailableDefaults
                log("Failed to open shared defaults for app group \(WidgetSharedStorage.appGroupIdentifier)")
            }
            widgetSyncError = syncError
            if didUpdateSnapshot {
                storage.reloadWidgets()
            }
        } catch {
            widgetSyncError = error
            log("Failed to mirror cities to shared defaults. Error: \(error)")
        }
    }
}
