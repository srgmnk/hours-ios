import XCTest
import SwiftUI
@testable import MapHarness

@MainActor final class OnboardingFlowTests: XCTestCase {
    func testNavigationKeepsProgressDuringResizeAndCompletesOnlyAtFinalAction() async throws {
        let defaults = UserDefaults.standard
        let saved = defaults.object(forKey: OnboardingStorageKey.hasCompleted)
        defaults.set(false, forKey: OnboardingStorageKey.hasCompleted)
        defer {
            if let saved { defaults.set(saved, forKey: OnboardingStorageKey.hasCompleted) }
            else { defaults.removeObject(forKey: OnboardingStorageKey.hasCompleted) }
        }
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        let parent = UIViewController()
        window.rootViewController = parent; window.makeKeyAndVisible()
        let host = UIHostingController(rootView: OnboardingView().environment(\.appTheme, .light))
        parent.addChild(host); parent.view.addSubview(host.view)
        host.view.frame = parent.view.bounds; host.didMove(toParent: parent)
        defer { window.isHidden = true; previous?.makeKeyAndVisible() }
        try await Task.sleep(for: .milliseconds(300))

        let next = try XCTUnwrap(elements(in: host.view).first { $0.accessibilityLabel == "Next up" })
        XCTAssertTrue(next.accessibilityActivate())
        try await Task.sleep(for: .milliseconds(300))
        XCTAssertNotNil(elements(in: host.view).first { $0.accessibilityLabel == "Jump up" })
        XCTAssertFalse(defaults.bool(forKey: OnboardingStorageKey.hasCompleted))

        // Resize the same hosted view; replacing the root would hide state resets.
        for size in [CGSize(width: 951, height: 669), CGSize(width: 669, height: 951),
                     CGSize(width: 470, height: 669), parent.view.bounds.size] {
            host.view.frame = CGRect(origin: .zero, size: size)
            host.view.layoutIfNeeded()
            try await Task.sleep(for: .milliseconds(100))
            let labels = elements(in: host.view).compactMap(\.accessibilityLabel)
            XCTAssertTrue(labels.contains("Jump up"))
            XCTAssertFalse(labels.contains("Next up"))
            XCTAssertFalse(defaults.bool(forKey: OnboardingStorageKey.hasCompleted))
        }
        let finish = try XCTUnwrap(elements(in: host.view).first { $0.accessibilityLabel == "Jump up" })
        XCTAssertTrue(finish.accessibilityActivate())
        try await Task.sleep(for: .milliseconds(300))
        XCTAssertTrue(defaults.bool(forKey: OnboardingStorageKey.hasCompleted))
        let domain = try XCTUnwrap(Bundle.main.bundleIdentifier)
        XCTAssertEqual(defaults.persistentDomain(forName: domain)?[OnboardingStorageKey.hasCompleted] as? Bool, true)
    }

    private func elements(in root: NSObject) -> [NSObject] {
        var seen = Set<ObjectIdentifier>()
        func visit(_ object: NSObject) -> [NSObject] {
            guard seen.insert(ObjectIdentifier(object)).inserted else { return [] }
            var result = [object]
            if let view = object as? UIView {
                for child in view.subviews { result += visit(child) }
            }
            let count = object.accessibilityElementCount()
            if count > 0 && count < 1_000 {
                for index in 0..<count {
                    if let child = object.accessibilityElement(at: index) as? NSObject { result += visit(child) }
                }
            }
            return result
        }
        return visit(root)
    }
}
