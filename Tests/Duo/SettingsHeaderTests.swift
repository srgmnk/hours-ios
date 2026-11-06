import XCTest
import SwiftUI
@testable import MapHarness

@MainActor final class SettingsHeaderTests: XCTestCase {
    func testCompactHeaderFitsFigmaCanvas() throws {
        let renderer = ImageRenderer(content: SettingsSheetView(usesCompactHeader: true).compactHeader)
        renderer.proposedSize = ProposedViewSize(width: 652, height: nil)
        let image = try XCTUnwrap(renderer.uiImage)
        XCTAssertEqual(image.size.width, 652, accuracy: 0.01)
        XCTAssertEqual(image.size.height, 458, accuracy: 0.01)
        // All three original layers share the Figma aspect ratio in both modes.
        for mode in ["light", "dark"] {
            for layer in ["back", "mid", "front"] {
                let image = try XCTUnwrap(UIImage(named: "settings_parallax_\(layer)_\(mode)"))
                XCTAssertEqual(532 * image.size.height / image.size.width, 457.998, accuracy: 0.001)
            }
        }
    }

    func testCompactSettingsReducesContentHeightAndKeepsNativeScrolling() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previousKeyWindow = scene.windows.first(where: \.isKeyWindow)
        defer { previousKeyWindow?.makeKeyAndVisible() }
        for theme in [AppTheme.light, .dark] {
            var heights: [CGFloat] = []
            for compact in [false, true] {
                let window = UIWindow(windowScene: scene)
                let host = UIHostingController(rootView: SettingsSheetView(usesCompactHeader: compact)
                    .environment(\.appTheme, theme)
                    .frame(width: 652, height: 661))
                window.rootViewController = host
                window.makeKeyAndVisible()
                defer { window.isHidden = true }
                try await Task.sleep(for: .milliseconds(300))
                host.view.layoutIfNeeded()
                let scroll = try XCTUnwrap(findScroll(in: host.view))
                heights.append(scroll.contentSize.height)
                XCTAssertTrue(scroll.isScrollEnabled)
                XCTAssertGreaterThan(scroll.contentSize.height, scroll.bounds.height)
                XCTAssertEqual(scroll.contentOffset.y, -scroll.adjustedContentInset.top, accuracy: 0.5)
                let start = scroll.contentOffset.y
                scroll.setContentOffset(CGPoint(x: 0, y: start + 100), animated: false)
                XCTAssertEqual(scroll.contentOffset.y, start + 100, accuracy: 0.5)
            }
            XCTAssertGreaterThan(heights[0], heights[1],
                "The compact header must expose more settings content initially")
        }
    }

    private func findScroll(in view: UIView) -> UIScrollView? {
        if let scroll = view as? UIScrollView { return scroll }
        return view.subviews.lazy.compactMap { self.findScroll(in: $0) }.first
    }

}
