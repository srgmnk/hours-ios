import Foundation

/// All filesystem URLs are redirected into a disposable test root. Reads/writes are captured in memory.
nonisolated final class IsolatedCityFileManager: FileManager, @unchecked Sendable {
    let testRoot: URL
    init(root: URL) { testRoot = root; super.init() }
    override func url(for directory: FileManager.SearchPathDirectory, in domain: FileManager.SearchPathDomainMask,
                      appropriateFor url: URL?, create shouldCreate: Bool) throws -> URL {
        testRoot.appendingPathComponent("ApplicationSupport")
    }
    override func containerURL(forSecurityApplicationGroupIdentifier groupIdentifier: String) -> URL? {
        testRoot.appendingPathComponent("WidgetContainer")
    }
}

@MainActor final class IsolatedCityStoreFixture {
    let root = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Hours-StoreFixture-" + UUID().uuidString)
    lazy var fileManager = IsolatedCityFileManager(root: root)
    var files: [URL: Data] = [:]
    var primaryWrites = 0
    var widgetReloads = 0
    var primaryURL: URL { root.appendingPathComponent("ApplicationSupport/cities.json") }
    init(_ cities: [City]) throws { files[primaryURL] = try JSONEncoder().encode(cities) }
    var storage: CityStore.Storage {
        CityStore.Storage(read: { [unowned self] url in
            precondition(url.path.hasPrefix(self.root.path + "/"))
            guard let data = self.files[url] else { throw CocoaError(.fileReadNoSuchFile) }
            return data
        }, write: { [unowned self] data, url in
            precondition(url.path.hasPrefix(self.root.path + "/"))
            self.files[url] = data
            if url == self.primaryURL { self.primaryWrites += 1 }
        }, sharedDefaults: { _ in nil }, reloadWidgets: { [unowned self] in self.widgetReloads += 1 })
    }
    func removeCreatedDirectories() { try? FileManager.default.removeItem(at: root) }
}
