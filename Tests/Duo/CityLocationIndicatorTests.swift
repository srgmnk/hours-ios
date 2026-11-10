import XCTest
import SwiftUI
@testable import MapHarness

@MainActor final class CityLocationIndicatorTests: XCTestCase {
    private let instant = Date(timeIntervalSince1970: 1735736400)
    private let bangkok = CitySearchItem(id: "location-bangkok", city: "Bangkok", country: "Thailand",
        timeZoneIdentifier: "Asia/Bangkok", aliases: [], canonicalID: "city:location-bangkok")
    private let moscow = CitySearchItem(id: "location-moscow", city: "Moscow", country: "Russia",
        timeZoneIdentifier: "Europe/Moscow", aliases: [], canonicalID: "city:location-moscow")

    private func card(_ city: City, primary: Bool, location: Bool, mode: CityViewPreference) -> CityCardView {
        CityCardView(city: city, selectedInstant: instant, referenceTimeZone: bangkok.asCity.timeZone,
                     isCurrent: primary, isUserCurrentLocation: location, cityViewPreference: mode,
                     cardBackgroundColor: AppTheme.light.surfaceCard)
    }

    // Render the actual shared title, isolating it from intentionally different Primary metadata.
    func testRenderedLocationIndicatorIsIndependentOfPrimaryInEveryModeAndAppearance() throws {
        for mode: CityViewPreference in [.basic, .compact, .cards] {
            for scheme: ColorScheme in [.light, .dark] {
                func title(primary: Bool, location: Bool) throws -> Data {
                    let renderer = ImageRenderer(content: card(moscow.asCity, primary: primary, location: location, mode: mode)
                        .cityTitle(fontSize: 14, locationSize: 12)
                        .frame(width: 180, height: 32)
                        .environment(\.appTheme, AppTheme.forColorScheme(scheme))
                        .environment(\.colorScheme, scheme))
                    renderer.scale = 2
                    return try XCTUnwrap(renderer.uiImage?.pngData())
                }
                let regular = try title(primary: false, location: false)
                let located = try title(primary: false, location: true)
                XCTAssertNotEqual(regular, located, "Location must visibly add the existing arrow")
                XCTAssertEqual(try title(primary: true, location: false), regular, "\(mode): Primary cannot add a location arrow")
                XCTAssertEqual(try title(primary: true, location: true), located, "\(mode): Location survives Primary changes")
            }
        }
    }

    private func apply(_ controller: CityListReorderViewController, cities: [City], mode: CityViewPreference,
                       location: CitySearchItem?) {
        controller.apply(cities: cities, selectedInstant: instant, userCurrentLocationItem: location,
                         cityViewPreference: mode, topInset: 0, bottomInset: 0,
                         cardBackgroundColor: AppTheme.light.surfaceCard)
        controller.view.layoutIfNeeded(); controller.collectionView.layoutIfNeeded()
    }

    func testReorderAndFileReloadKeepLocationIdentityAcrossModes() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let manager = LocationIndicatorFileManager(root: root)
        var storage = CityStore.Storage()
        storage.sharedDefaults = { _ in nil }; storage.reloadWidgets = {}
        let store = CityStore(fileManager: manager, storage: storage)
        store.cities = [bangkok.asCity, moscow.asCity,
                        City(name: "Cairo", timeZoneID: "Africa/Cairo", canonicalID: "city:location-cairo")]
        let controller = CityListReorderViewController()
        controller.loadViewIfNeeded(); controller.view.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        controller.onCitiesChanged = { store.cities = $0 }
        for mode: CityViewPreference in [.cards, .basic, .compact, .cards] {
            apply(controller, cities: store.cities, mode: mode, location: bangkok)
            for destinationCity in [moscow, bangkok, moscow, bangkok] {
                let source = try XCTUnwrap(controller.citiesLocal.firstIndex { $0.id == destinationCity.canonicalIdentity })
                controller.collectionView(controller.collectionView, moveItemAt: IndexPath(item: source, section: 0),
                                          to: IndexPath(item: 0, section: 0))
                XCTAssertEqual(controller.citiesLocal.primaryCity?.id, destinationCity.canonicalIdentity)
                let locationIndex = try XCTUnwrap(controller.currentLocationMatchIndex())
                XCTAssertEqual(controller.citiesLocal[locationIndex].id, bangkok.canonicalIdentity)
                try await Task.sleep(for: .milliseconds(50))
                XCTAssertEqual(store.cities, controller.citiesLocal)
                let reopened = CityStore(fileManager: manager, storage: storage)
                XCTAssertEqual(reopened.cities, store.cities)
                XCTAssertEqual(reopened.cities.primaryCity?.id, destinationCity.canonicalIdentity)
                let relaunchedController = CityListReorderViewController()
                relaunchedController.loadViewIfNeeded()
                apply(relaunchedController, cities: reopened.cities, mode: mode, location: bangkok)
                XCTAssertEqual(reopened.cities[try XCTUnwrap(relaunchedController.currentLocationMatchIndex())].id, bangkok.canonicalIdentity)
                XCTAssertEqual(controller.selectedInstant, instant)
                XCTAssertEqual(Set(store.cities.map(\.id)).count, 3)
            }
        }
        controller.deleteCity(id: moscow.canonicalIdentity)
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertFalse(store.cities.contains { $0.id == moscow.canonicalIdentity })
        XCTAssertEqual(controller.citiesLocal[try XCTUnwrap(controller.currentLocationMatchIndex())].id, bangkok.canonicalIdentity)
        XCTAssertEqual(CityStore(fileManager: manager, storage: storage).cities, store.cities)
    }

    func testAuthoritativeLocationUpdatesAndMissingLocationDoNotFollowPrimary() throws {
        let controller = CityListReorderViewController()
        controller.loadViewIfNeeded()
        var renamedBangkok = bangkok.asCity
        renamedBangkok.customDisplayName = "Home"
        let cities = [moscow.asCity, renamedBangkok]
        for mode: CityViewPreference in [.basic, .compact, .cards] {
            apply(controller, cities: cities, mode: mode, location: bangkok)
            XCTAssertEqual(controller.currentLocationMatchIndex(), 1, "Canonical identity survives a renamed city")
            apply(controller, cities: cities, mode: mode, location: moscow)
            XCTAssertEqual(controller.currentLocationMatchIndex(), 0)
            apply(controller, cities: cities, mode: mode, location: nil)
            XCTAssertNil(controller.currentLocationMatchIndex(), "Primary alone is not location evidence")
            XCTAssertEqual(controller.citiesLocal.primaryCity?.id, moscow.canonicalIdentity)
        }
    }

    func testReusedCellConfigurationRendersSameLocationIndicatorAsFreshCell() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        let host = UIViewController()
        window.rootViewController = host; window.makeKeyAndVisible()
        defer { window.isHidden = true; previous?.makeKeyAndVisible() }
        let reused = CityListReorderCollectionCell(frame: .zero)
        for mode: CityViewPreference in [.cards, .basic, .compact, .cards] {
            for (city, primary, located) in [(bangkok.asCity, true, true), (moscow.asCity, true, false),
                                              (bangkok.asCity, false, true), (moscow.asCity, false, false)] {
                func render(_ cell: CityListReorderCollectionCell) async throws -> Data {
                    cell.frame = CGRect(x: 0, y: 0, width: mode == .cards ? 184.5 : 377,
                                        height: mode == .cards ? 200 : (mode == .compact ? 88 : 140))
                    cell.configure(city: city, selectedInstant: instant, referenceTimeZone: bangkok.asCity.timeZone,
                                   isCurrent: primary, isUserCurrentLocation: located, cityViewPreference: mode,
                                   cardBackgroundColor: AppTheme.light.surfaceCard, cardTheme: .light)
                    // Mount the configuration explicitly: these cells are outside a
                    // collection, so UIKit does not manage their hosting-view lifecycle.
                    let rendered = try XCTUnwrap(cell.contentConfiguration).makeContentView()
                    rendered.frame = cell.bounds
                    host.view.addSubview(rendered)
                    host.view.layoutIfNeeded(); rendered.layoutIfNeeded()
                    try await Task.sleep(for: .milliseconds(100))
                    let image = UIGraphicsImageRenderer(bounds: rendered.bounds).image { _ in
                        rendered.drawHierarchy(in: rendered.bounds, afterScreenUpdates: true)
                    }
                    rendered.removeFromSuperview()
                    return try XCTUnwrap(image.pngData())
                }
                reused.prepareForReuse()
                let reusedImage = try await render(reused)
                let freshImage = try await render(CityListReorderCollectionCell(frame: .zero))
                XCTAssertEqual(reusedImage, freshImage, "\(mode), \(city.name): no stale location indicator")
            }
        }
    }
}

private final class LocationIndicatorFileManager: FileManager, @unchecked Sendable {
    let root: URL
    init(root: URL) { self.root = root; super.init() }
    override func url(for directory: FileManager.SearchPathDirectory, in domain: FileManager.SearchPathDomainMask,
                      appropriateFor url: URL?, create shouldCreate: Bool) throws -> URL {
        if directory == .applicationSupportDirectory { return root }
        return try super.url(for: directory, in: domain, appropriateFor: url, create: shouldCreate)
    }
}
