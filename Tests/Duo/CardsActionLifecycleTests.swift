import XCTest
import SwiftUI
import Combine
@testable import MapHarness

@MainActor final class CardsActionLifecycleTests: XCTestCase {
    private let instant = Date(timeIntervalSince1970: 1735736400)
    private var cities: [City] {
        [City(name: "Bangkok", timeZoneID: "Asia/Bangkok", canonicalID: "city:lifecycle-bangkok"),
         City(name: "Moscow", timeZoneID: "Europe/Moscow", canonicalID: "city:lifecycle-moscow")]
    }

    func testReuseRetiresObservedPresentationWithoutPublishingOrCompleting() async throws {
        let cell = CityListReorderCollectionCell(frame: CGRect(x: 0, y: 0, width: 184.5, height: 200))
        func configure(_ city: City) {
            cell.configure(city: city, selectedInstant: instant, referenceTimeZone: cities[0].timeZone,
                           isCurrent: city.id == cities[0].id, isUserCurrentLocation: city.id == cities[0].id,
                           cityViewPreference: .cards, cardBackgroundColor: AppTheme.light.surfaceCard)
        }
        configure(cities[0])
        let retired = cell.actionPresentation
        retired.updateInteractiveProgress(0.5)
        retired.settle(open: true)
        var publications = 0
        var firstPublicationStack = ""
        let subscription = retired.objectWillChange.sink {
            if publications == 0 { firstPublicationStack = Thread.callStackSymbols.joined(separator: "\n") }
            publications += 1
        }
        cell.prepareForReuse()
        configure(cities[1])
        XCTAssertFalse(cell.actionPresentation === retired)
        XCTAssertEqual(cell.actionPresentation.progress, 0)
        XCTAssertFalse(cell.actionPresentation.buttonsEnabled)
        XCTAssertEqual(publications, 0, "Retiring hosted content must not publish into SwiftUI reconciliation\n\(firstPublicationStack)")
        try await Task.sleep(for: .milliseconds(300))
        XCTAssertEqual(publications, 0, "An obsolete completion must not re-enable retired actions")
        XCTAssertFalse(cell.actionPresentation.buttonsEnabled)
        withExtendedLifetime(subscription) {}
    }

    func testRepresentableModeChangesAndExternalDeletionDoNotPublishFromRetiredModels() async throws {
        let defaults = UserDefaults.standard
        let saved = defaults.object(forKey: CityViewPreference.storageKey)
        defer { defaults.set(saved, forKey: CityViewPreference.storageKey) }
        defaults.set("cards", forKey: CityViewPreference.storageKey)
        let data = try JSONEncoder().encode(cities)
        let store = CityStore(storage: .init(read: { _ in data }, write: { _, _ in },
                                            sharedDefaults: { _ in nil }, reloadWidgets: {}))
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        let host = UIHostingController(rootView: LifecycleListFixture(store: store, instant: instant))
        window.rootViewController = host; window.makeKeyAndVisible()
        defer { window.isHidden = true; previous?.makeKeyAndVisible() }
        func find(_ vc: UIViewController) -> CityListReorderViewController? {
            (vc as? CityListReorderViewController) ?? vc.children.lazy.compactMap(find).first
        }
        try await Task.sleep(for: .milliseconds(500))
        let controller = try XCTUnwrap(find(host))
        for transition in ["basic", "compact", "delete-open", "delete-interactive"] {
            store.cities = cities
            defaults.set("cards", forKey: CityViewPreference.storageKey)
            try await Task.sleep(for: .milliseconds(200))
            let cell = try XCTUnwrap(controller.actionCell(for: cities[1].id))
            let retired = cell.actionPresentation
            if transition == "delete-interactive" {
                controller.actionSwipeCityID = cities[1].id
                controller.updateCardActionSwipe(translation: -48)
            } else {
                controller.setOpenActionsCityID(cities[1].id)
                try await Task.sleep(for: .milliseconds(300))
                XCTAssertTrue(retired.buttonsEnabled)
            }
            var publications = 0
            var firstPublicationStack = ""
            let subscription = retired.objectWillChange.sink {
                if publications == 0 { firstPublicationStack = Thread.callStackSymbols.joined(separator: "\n") }
                publications += 1
            }
            if transition.hasPrefix("delete") { store.cities.removeLast() }
            else { defaults.set(transition, forKey: CityViewPreference.storageKey) }
            try await Task.sleep(for: .milliseconds(350))
            XCTAssertEqual(publications, 0, "\(transition)\n\(firstPublicationStack)")
            XCTAssertTrue(find(host) === controller)
            XCTAssertNil(controller.openActionsCityID)
            XCTAssertNil(controller.actionSwipeCityID)
            XCTAssertEqual(controller.selectedInstant, instant)
            withExtendedLifetime(subscription) {}
        }
    }
}

@MainActor private struct LifecycleListFixture: View {
    @ObservedObject var store: CityStore
    let instant: Date
    var body: some View {
        CityListReorderUIKitView(cities: $store.cities, selectedInstant: instant, userCurrentLocationItem: nil,
            topSafeAreaInset: 0, bottomContentInset: 0, onRenameRequested: { _ in }, onCitySelected: { _ in })
            .environment(\.appTheme, .light)
    }
}
