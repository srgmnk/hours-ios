import XCTest
import SwiftUI
@testable import MapHarness

@MainActor final class LiveCityViewPreferenceTests: XCTestCase {
    func testRetainedListObservesPersistedStyleWithoutParentRecreation() async throws {
        let defaults = UserDefaults.standard
        let key = CityViewPreference.storageKey
        let saved = defaults.object(forKey: key)
        defer { defaults.set(saved, forKey: key) }
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let cities = (0..<30).map { City(name: "City \($0)", timeZoneID: "UTC", canonicalID: "live-\($0)") }
        for viewport: CGSize? in [nil, CGSize(width: 382, height: 678), CGSize(width: 340, height: 669), CGSize(width: 455, height: 669)] {
            defaults.set("basic", forKey: key)
            let list = CityListReorderUIKitView(cities: .constant(cities), selectedInstant: Date(timeIntervalSince1970: 1735736400), userCurrentLocationItem: nil, topSafeAreaInset: 25, bottomContentInset: 34, onRenameRequested: { _ in }, onCitySelected: { _ in }, duoViewport: viewport)
            let host = UIHostingController(rootView: list.frame(width: viewport?.width ?? 393, height: 669))
            let window = UIWindow(windowScene: scene)
            window.rootViewController = host; window.makeKeyAndVisible()
            defer { window.isHidden = true; previous?.makeKeyAndVisible() }
            try await Task.sleep(for: .milliseconds(300))
            func find(_ vc: UIViewController) -> CityListReorderViewController? {
                if let list = vc as? CityListReorderViewController { return list }
                return vc.children.lazy.compactMap { find($0) }.first
            }
            for _ in 0..<30 where find(host) == nil {
                host.view.layoutIfNeeded()
                try await Task.sleep(for: .milliseconds(100))
            }
            let controller = try XCTUnwrap(find(host))
            let collection = controller.collectionView
            collection.setContentOffset(CGPoint(x: 0, y: 300), animated: false)
            for style in ["compact", "basic", "compact", "basic"] {
                defaults.set(style, forKey: key)
                try await Task.sleep(for: .milliseconds(200))
                collection.layoutIfNeeded()
                XCTAssertTrue(find(host) === controller)
                XCTAssertEqual(controller.cityViewPreference.rawValue, style)
                XCTAssertEqual(controller.citiesLocal.map(\.id), cities.map(\.id))
                XCTAssertGreaterThan(collection.contentOffset.y, 0, "Style changes must not reset the list to the top")
                let expected: CGFloat = style == "basic" ? 140 : 88
                for index in [0, 4, 20] {
                    collection.scrollToItem(at: IndexPath(item: index, section: 0), at: .top, animated: false)
                    collection.layoutIfNeeded()
                    try await Task.sleep(for: .milliseconds(50))
                    collection.layoutIfNeeded()
                    let a = try XCTUnwrap(collection.layoutAttributesForItem(at: IndexPath(item: index, section: 0)))
                    let b = try XCTUnwrap(collection.layoutAttributesForItem(at: IndexPath(item: index + 1, section: 0)))
                    XCTAssertEqual(a.frame.height, expected, accuracy: 0.5)
                    XCTAssertEqual(b.frame.minY - a.frame.maxY, 8, accuracy: 0.5)
                }
                collection.setContentOffset(CGPoint(x: 0, y: 300), animated: false)
                collection.layoutIfNeeded()
                try await Task.sleep(for: .milliseconds(200))
            }
        }
    }
}
