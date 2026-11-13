import XCTest
import SwiftUI
@testable import MapHarness

@MainActor final class SettingsContentWidthTests: XCTestCase {
    func testOnlyClosedAndOpenedSplitRecoverActualInsets() {
        let landscape = CGSize(width: 951, height: 669)
        let portrait = CGSize(width: 669, height: 951)
        for hinge: DuoHingeState.Status in [.unavailable, .closed, .partiallyOpen, .fullyOpen] {
            for (window, screen, split) in [
                (landscape, landscape, false), (portrait, portrait, false),
                (CGSize(width: 469, height: 669), landscape, true),
                (CGSize(width: 469, height: 334), landscape, false),
                (CGSize(width: 466, height: 678), CGSize(width: 466, height: 678), false)
            ] {
                let layout = SettingsContentWidthObserver.configuration(
                    hinge: hinge, window: window, screen: screen)
                let isSplit = (hinge == .fullyOpen || hinge == .partiallyOpen) && split
                XCTAssertEqual(layout.isSplitView, isSplit)
                XCTAssertEqual(layout.expandsContent, hinge == .closed || isSplit)
            }
        }
    }

    func testExpandedScrollRecoversEitherInsetWithinViewport() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previousKey = scene.windows.first(where: \.isKeyWindow)
        defer { previousKey?.makeKeyAndVisible() }
        for theme in [AppTheme.light, .dark] {
            for (left, right, edge): (CGFloat, CGFloat, Edge.Set) in [(13, 76, .trailing), (76, 0, .leading), (0, 0, .trailing)] {
                let state = SettingsWidthFixtureState()
                let host = UIHostingController(rootView: SettingsWidthFixture(state: state).environment(\.appTheme, theme))
                let window = UIWindow(windowScene: scene)
                window.frame = CGRect(x: 0, y: 0, width: 466, height: 678)
                host.additionalSafeAreaInsets = .init(top: 19, left: left, bottom: 34, right: right)
                window.rootViewController = host; window.makeKeyAndVisible()
                defer { window.isHidden = true }
                try await Task.sleep(for: .milliseconds(300))
                host.view.layoutIfNeeded()
                let scroll = try XCTUnwrap(descendants(host.view).compactMap { $0 as? UIScrollView }.first)
                let bar = try XCTUnwrap(descendants(host.view).compactMap { $0 as? UINavigationBar }.first)
                let before = scroll.convert(scroll.bounds, to: window)
                let contentHeight = scroll.contentSize.height
                let contentWidth = scroll.contentSize.width
                let recoveredInset = edge == .leading ? host.view.safeAreaInsets.left : host.view.safeAreaInsets.right
                let retainedInset = edge == .leading ? host.view.safeAreaInsets.right : host.view.safeAreaInsets.left
                let barFrame = bar.convert(bar.bounds, to: window)
                let barImage = snapshot(bar)
                state.edges = edge
                try await Task.sleep(for: .milliseconds(300))
                host.view.layoutIfNeeded()
                let after = scroll.convert(scroll.bounds, to: window)
                XCTAssertEqual(after.minX, before.minX, accuracy: 0.5)
                XCTAssertEqual(after.maxX, host.view.bounds.maxX, accuracy: 0.5)
                XCTAssertEqual(after.minY, before.minY, accuracy: 0.5)
                XCTAssertEqual(after.height, before.height, accuracy: 0.5)
                XCTAssertEqual(scroll.contentSize.height - contentHeight, recoveredInset * 457.998 / 532, accuracy: 1, "Artwork scales proportionally to the recovered width")
                XCTAssertEqual(scroll.contentSize.width, contentWidth + recoveredInset, accuracy: 0.5)
                XCTAssertEqual(scroll.contentSize.width, scroll.bounds.width - retainedInset, accuracy: 0.5,
                               "Recover only the requested inset within the assigned viewport")
                XCTAssertEqual(bar.convert(bar.bounds, to: window), barFrame)
                XCTAssertEqual(snapshot(bar), barImage, "Header content must remain unchanged")
                let offset = scroll.contentOffset.y
                scroll.setContentOffset(CGPoint(x: 0, y: offset + 100), animated: false)
                XCTAssertEqual(scroll.contentOffset.y, offset + 100, accuracy: 0.5)
            }
        }
    }

    func testFullWidthSectionsAtDynamicType() throws {
        for type in [DynamicTypeSize.large, .xxxLarge, .accessibility5] {
            for theme in [AppTheme.light, .dark] {
                let settings = SettingsSheetView()
                let before = ImageRenderer(content: settings.settingsBlock
                    .environment(\.appTheme, theme).environment(\.dynamicTypeSize, type).frame(width: 358))
                let after = ImageRenderer(content: settings.settingsBlock
                    .environment(\.appTheme, theme).environment(\.dynamicTypeSize, type).frame(width: 434))
                XCTAssertEqual(try XCTUnwrap(before.uiImage).size.height, try XCTUnwrap(after.uiImage).size.height)
                XCTAssertEqual(try XCTUnwrap(after.uiImage).size.width, 434)
            }
        }
    }

    private func descendants(_ view: UIView) -> [UIView] {
        [view] + view.subviews.flatMap(descendants)
    }
    private func snapshot(_ view: UIView) -> Data? {
        UIGraphicsImageRenderer(bounds: view.bounds).image { view.layer.render(in: $0.cgContext) }.pngData()
    }
}

@MainActor private final class SettingsWidthFixtureState: ObservableObject {
    @Published var edges: Edge.Set = []
}
private struct SettingsWidthFixture: View {
    @ObservedObject var state: SettingsWidthFixtureState
    var body: some View {
        NavigationStack {
            SettingsSheetView().mainContent(expandedEdges: [])
                .modifier(SettingsContentSafeArea(enabled: !state.edges.isEmpty, railOnRight: state.edges != .leading))
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarLeading) { SettingsSheetView().closeButton } }
        }
    }
}
