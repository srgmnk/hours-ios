import XCTest
import SwiftUI
@testable import MapHarness

/// Exercises the real Settings NavigationStack in a retained SwiftUI sheet.
/// Changing the existing persisted preference follows the same path as its buttons.
@MainActor final class SettingsAppearanceTests: XCTestCase {
    func testLivePreferenceChangesReachNativeSheetWithoutResettingPresentation() async throws {
        let defaults = UserDefaults.standard
        let key = AppAppearancePreference.storageKey
        let saved = defaults.object(forKey: key)
        defer {
            if let saved { defaults.set(saved, forKey: key) }
            else { defaults.removeObject(forKey: key) }
        }
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previousKeyWindow = scene.windows.first(where: \.isKeyWindow)
        defer { previousKeyWindow?.makeKeyAndVisible() }

        // The sequence contains every directed transition, including repeated overrides.
        let sequence: [AppAppearancePreference] = [.light, .dark, .light, .system,
                                                   .dark, .system, .dark, .light, .dark, .light]
        for systemStyle in [UIUserInterfaceStyle.light, .dark] {
            for compactHeader in [false, true] {
                defaults.set(AppAppearancePreference.system.rawValue, forKey: key)
                let presentation = SettingsAppearancePresentation()
                var observed: (ColorScheme, Bool)?
                let window = UIWindow(windowScene: scene)
                window.overrideUserInterfaceStyle = systemStyle
                let root = SettingsAppearanceRoot(presentation: presentation, compactHeader: compactHeader) {
                    observed = ($0, $1)
                }
                let host = UIHostingController(rootView: root)
                window.rootViewController = host
                window.makeKeyAndVisible()
                defer { window.isHidden = true }
                try await settle { host.view.window != nil }
                presentation.isPresented = true
                try await settle { host.presentedViewController != nil }
                let sheet = try XCTUnwrap(host.presentedViewController)
                try await settle { self.navigationController(in: sheet)?.navigationBar.window != nil }
                let navigation = try XCTUnwrap(navigationController(in: sheet))
                let bar = navigation.navigationBar
                let scroll = try XCTUnwrap(descendants(of: sheet.view).compactMap { $0 as? UIScrollView }.first)
                try await settle { scroll.bounds.height > 0 && scroll.contentSize.height > scroll.bounds.height }
                try await settle { sheet.transitionCoordinator == nil }
                // Native scroll-edge chrome can contract on the first scroll.
                // Record geometry after that layout, not during sheet entrance.
                scroll.setContentOffset(CGPoint(x: 0, y: -scroll.adjustedContentInset.top + 100), animated: false)
                try await Task.sleep(for: .milliseconds(300))
                window.layoutIfNeeded()
                try await settle { self.closeControl(in: bar) != nil }
                let initialDepth = navigation.viewControllers.count
                let initialSheetFrame = sheet.view.frame
                let initialBarFrame = bar.frame
                let initialClose = try XCTUnwrap(closeControl(in: bar))
                let initialCloseSize = initialClose.bounds.size
                var prior = AppAppearancePreference.system

                for (index, preference) in sequence.enumerated() {
                    // A nonzero offset detects identity replacement and content resets.
                    let maximumOffset = max(-scroll.adjustedContentInset.top,
                        scroll.contentSize.height - scroll.bounds.height + scroll.adjustedContentInset.bottom)
                    let target = min(maximumOffset, -scroll.adjustedContentInset.top + CGFloat(100 + index * 8))
                    scroll.setContentOffset(CGPoint(x: 0, y: target), animated: false)
                    defaults.set(preference.rawValue, forKey: key)
                    let expected: UIUserInterfaceStyle = preference == .system ? systemStyle : (preference == .dark ? .dark : .light)
                    try await settle {
                        window.layoutIfNeeded()
                        return bar.traitCollection.userInterfaceStyle == expected &&
                            observed?.0 == (expected == .dark ? ColorScheme.dark : .light) &&
                            observed?.1 == (expected == .dark)
                    }
                    let context = "system=\(systemStyle.rawValue), compact=\(compactHeader), \(prior.rawValue)→\(preference.rawValue)"
                    XCTAssertTrue(host.presentedViewController === sheet, context)
                    XCTAssertTrue(navigationController(in: sheet) === navigation, context)
                    XCTAssertTrue(descendants(of: sheet.view).contains { $0 === scroll }, context)
                    XCTAssertEqual(navigation.viewControllers.count, initialDepth, context)
                    XCTAssertEqual(scroll.contentOffset.y, target, accuracy: 0.5, context)
                    XCTAssertEqual(sheet.view.frame, initialSheetFrame, context)
                    XCTAssertEqual(bar.frame, initialBarFrame, context)
                    XCTAssertEqual(bar.traitCollection.userInterfaceStyle, expected, context)
                    XCTAssertEqual(sheet.traitCollection.userInterfaceStyle, expected, context)
                    XCTAssertEqual(observed?.0, expected == .dark ? .dark : .light, context)
                    XCTAssertEqual(observed?.1, expected == .dark, context)
                    XCTAssertEqual(navigation.topViewController?.navigationItem.title, "Settings", context)
                    XCTAssertEqual(descendants(of: sheet.view).compactMap { $0 as? UINavigationBar }.count, 1, context)

                    let title = try XCTUnwrap(descendants(of: bar).compactMap { $0 as? UILabel }
                        .first { $0.text == "Settings" || $0.attributedText?.string == "Settings" })
                    XCTAssertEqual(title.traitCollection.userInterfaceStyle, expected, context)
                    let titleColor = title.textColor.resolvedColor(with: title.traitCollection)
                    XCTAssertEqual(luminance(titleColor) > 0.5, expected == .dark, "Native title foreground: \(context)")
                    let close = try XCTUnwrap(closeControl(in: bar))
                    XCTAssertEqual(close.traitCollection.userInterfaceStyle, expected, context)
                    XCTAssertEqual(close.bounds.size, initialCloseSize, context)
                    // Includes hosted symbols and native glass, even when the
                    // toolbar action is not backed by a UIImageView.
                    for view in descendants(of: close) where !view.isHidden {
                        XCTAssertEqual(view.traitCollection.userInterfaceStyle, expected, context)
                    }
                    if (prior == .dark && preference == .light) ||
                        (prior == .light && preference == .dark) || preference == .system {
                        let image = UIGraphicsImageRenderer(size: window.bounds.size).image { _ in
                            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
                        }
                        let attachment = XCTAttachment(image: image)
                        attachment.name = "settings-\(prior.rawValue)-to-\(preference.rawValue)-system-\(systemStyle.rawValue)-compact-\(compactHeader)-\(index)"
                        attachment.lifetime = .keepAlways
                        add(attachment)
                    }
                    prior = preference
                }

                // System must keep following live traits after a manual override,
                // even though this presentation receives an explicit resolved scheme.
                defaults.set(AppAppearancePreference.system.rawValue, forKey: key)
                let opposite: UIUserInterfaceStyle = systemStyle == .dark ? .light : .dark
                for style in [systemStyle, opposite, systemStyle] {
                    window.overrideUserInterfaceStyle = style
                    try await settle {
                        bar.traitCollection.userInterfaceStyle == style &&
                            observed?.0 == (style == .dark ? ColorScheme.dark : .light) &&
                            observed?.1 == (style == .dark)
                    }
                    XCTAssertTrue(host.presentedViewController === sheet)
                    XCTAssertEqual(bar.traitCollection.userInterfaceStyle, style)
                    XCTAssertEqual(closeControl(in: bar)?.traitCollection.userInterfaceStyle, style)
                }

                // Reopening uses the persisted override and keeps a single native bar.
                defaults.set(AppAppearancePreference.light.rawValue, forKey: key)
                presentation.isPresented = false
                try await settle { host.presentedViewController == nil }
                presentation.isPresented = true
                try await settle { self.navigationController(in: host.presentedViewController)?.navigationBar.traitCollection.userInterfaceStyle == .light }
                let reopened = try XCTUnwrap(host.presentedViewController)
                XCTAssertEqual(descendants(of: reopened.view).compactMap { $0 as? UINavigationBar }.count, 1)
                XCTAssertEqual(defaults.string(forKey: key), AppAppearancePreference.light.rawValue)
                presentation.isPresented = false
                try await settle { host.presentedViewController == nil }
            }
        }
    }

    private func settle(_ condition: () -> Bool) async throws {
        for _ in 0..<30 {
            if condition() { return }
            try await Task.sleep(for: .milliseconds(100))
        }
        // Continue through the assertions to retain useful before-fix evidence.
        XCTAssertTrue(condition(), "Settings appearance did not settle within three seconds")
    }

    private func navigationController(in controller: UIViewController?) -> UINavigationController? {
        guard let controller else { return nil }
        if let navigation = controller as? UINavigationController { return navigation }
        return controller.children.lazy.compactMap { self.navigationController(in: $0) }.first
    }

    private func descendants(of view: UIView) -> [UIView] {
        [view] + view.subviews.flatMap { descendants(of: $0) }
    }

    private func closeControl(in bar: UINavigationBar) -> UIControl? {
        // Settings has a single leading toolbar action: its native Close button.
        descendants(of: bar).compactMap { $0 as? UIControl }.first {
            !$0.isHidden && $0.bounds.width > 0 && $0.bounds.height > 0
        }
    }

    private func luminance(_ color: UIColor) -> CGFloat {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return 0.2126 * red + 0.7152 * green + 0.0722 * blue
    }
}

@MainActor private final class SettingsAppearancePresentation: ObservableObject {
    @Published var isPresented = false
}

/// Mirrors ThemedRootView's appearance boundary without constructing CityStore.
private struct SettingsAppearanceRoot: View {
    @ObservedObject var presentation: SettingsAppearancePresentation
    let compactHeader: Bool
    let report: (ColorScheme, Bool) -> Void
    @AppStorage(AppAppearancePreference.storageKey) private var rawValue = AppAppearancePreference.system.rawValue
    @Environment(\.colorScheme) private var systemColorScheme

    var body: some View {
        let preference = AppAppearancePreference.from(rawValue: rawValue)
        SettingsAppearanceOwner(presentation: presentation, compactHeader: compactHeader, report: report)
            .environment(\.appTheme, AppTheme.forColorScheme(preference.resolvedColorScheme(systemColorScheme: systemColorScheme)))
            .preferredColorScheme(preference.preferredColorSchemeOverride)
    }
}

private struct SettingsAppearanceOwner: View {
    @ObservedObject var presentation: SettingsAppearancePresentation
    let compactHeader: Bool
    let report: (ColorScheme, Bool) -> Void
    var body: some View {
        Color.clear.sheet(isPresented: $presentation.isPresented) {
            SettingsSheetView(usesCompactHeader: compactHeader)
                .background { SettingsAppearanceProbe(report: report) }
        }
    }
}

private struct SettingsAppearanceProbe: UIViewRepresentable {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appTheme) private var theme
    let report: (ColorScheme, Bool) -> Void
    func makeUIView(context: Context) -> UIView { UIView() }
    func updateUIView(_ view: UIView, context: Context) { report(colorScheme, theme.variant == .dark) }
}
