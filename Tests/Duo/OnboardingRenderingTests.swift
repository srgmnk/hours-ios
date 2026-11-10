import XCTest
import SwiftUI
@testable import MapHarness

@MainActor final class OnboardingRenderingTests: XCTestCase {
    func testBothStepsRenderInEveryDuoCompositionAndAppearance() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        let parent = UIViewController()
        window.rootViewController = parent
        window.makeKeyAndVisible()
        defer { window.isHidden = true; previous?.makeKeyAndVisible() }
        let fixtures: [(String, CGSize, CGFloat, Bool?)] = [
            ("outer", CGSize(width: 466, height: 678), 80, true),
            ("landscape", CGSize(width: 951, height: 669), 80, true),
            ("portrait", CGSize(width: 669, height: 951), 0, nil),
            ("split-left", CGSize(width: 470, height: 669), 0, false),
            ("split-right", CGSize(width: 469, height: 669), 84, true)
        ]
        for dark in [false, true] {
            window.overrideUserInterfaceStyle = dark ? .dark : .light
            for (name, size, side, right) in fixtures {
                var hinge = DuoHingeState(); hinge.receive(name == "outer" ? .closed : .fullyOpen)
                let top: CGFloat = name == "portrait" ? 84 : 0
                let layout = try XCTUnwrap(DuoOnboardingLayout.resolve(.init(
                    hinge: hinge, bounds: CGRect(origin: .zero, size: size),
                    safeContent: CGRect(x: 0, y: top, width: size.width - side, height: size.height - top - 24),
                    railOnRight: right, occlusions: [], divisions: [])))
                for step in OnboardingStep.allCases {
                    let host = UIHostingController(rootView: DuoOnboardingStepView(step: step, layout: layout)
                        .background(dark ? AppTheme.dark.screenBackground : AppTheme.light.screenBackground)
                        .environment(\.appTheme, dark ? .dark : .light)
                        .environment(\.colorScheme, dark ? .dark : .light))
                    // Fixed fixture bounds are design renders, not evidence of live hinge routing.
                    host.safeAreaRegions = []
                    parent.addChild(host); parent.view.addSubview(host.view)
                    host.view.frame = CGRect(origin: .zero, size: size)
                    host.didMove(toParent: parent)
                    host.view.layoutIfNeeded()
                    try await Task.sleep(for: .milliseconds(150))
                    let format = UIGraphicsImageRendererFormat(); format.scale = 1
                    let image = UIGraphicsImageRenderer(bounds: host.view.bounds, format: format).image { _ in
                        XCTAssertTrue(host.view.drawHierarchy(in: host.view.bounds, afterScreenUpdates: true))
                    }
                    XCTAssertEqual(image.size, size)
                    let attachment = XCTAttachment(image: image)
                    attachment.name = "onboarding-\(name)-step\(step.rawValue+1)-\(dark ? "dark" : "light")"
                    attachment.lifetime = .keepAlways; add(attachment)
                    host.willMove(toParent: nil); host.view.removeFromSuperview(); host.removeFromParent()
                }
            }
        }
    }

    func testConventionalOnboardingCapture() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        let host = UIHostingController(rootView: OnboardingView().environment(\.appTheme, .light).preferredColorScheme(.light))
        window.rootViewController = host; window.makeKeyAndVisible()
        defer { window.isHidden = true; previous?.makeKeyAndVisible() }
        try await Task.sleep(for: .milliseconds(400))
        XCTAssertLessThan(window.bounds.width, 500, "Run on a conventional iPhone")
        let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
            XCTAssertTrue(window.drawHierarchy(in: window.bounds, afterScreenUpdates: true))
        }
        let attachment = XCTAttachment(image: image); attachment.name = "conventional-onboarding"
        attachment.lifetime = .keepAlways; add(attachment)
    }
}
