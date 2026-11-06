import XCTest
import SwiftUI
@testable import MapHarness

@MainActor final class AppearanceTests: XCTestCase {
    func testPreferenceStorageAndOverridesRemainCompatible() {
        XCTAssertEqual(AppAppearancePreference.storageKey, "appearancePreference")
        XCTAssertEqual(AppAppearancePreference.from(rawValue: "unknown"), .system)
        XCTAssertNil(AppAppearancePreference.system.preferredColorSchemeOverride)
        for scheme in [ColorScheme.light, .dark] {
            XCTAssertEqual(AppAppearancePreference.system.resolvedColorScheme(systemColorScheme: scheme), scheme)
            XCTAssertEqual(AppAppearancePreference.light.preferredColorSchemeOverride, .light)
            XCTAssertEqual(AppAppearancePreference.dark.preferredColorSchemeOverride, .dark)
        }
    }

    func testSwiftUIPaletteAndMaterialSchemeTrackLiveUIKitTraits() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previousKeyWindow = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        var observed: (ColorScheme, Bool)?
        let host = UIHostingController(rootView: ThemedPaletteProbe { observed = ($0, $1) })
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true; previousKeyWindow?.makeKeyAndVisible() }
        for style in [UIUserInterfaceStyle.light, .dark, .light, .dark, .light] {
            window.overrideUserInterfaceStyle = style
            window.layoutIfNeeded()
            try await Task.sleep(for: .milliseconds(200))
            let value = try XCTUnwrap(observed)
            XCTAssertEqual(value.0 == .dark, style == .dark)
            XCTAssertEqual(value.1, style == .dark, "Custom palette must follow the same traits as SwiftUI materials")
        }
    }

    func testProductionRootUpdatesBackgroundThroughRetainedGeometry() async throws {
        let defaults = UserDefaults.standard
        let keys = [AppAppearancePreference.storageKey, OnboardingStorageKey.hasCompleted]
        let saved = keys.map { defaults.object(forKey: $0) }
        defaults.set("system", forKey: keys[0])
        defaults.set(true, forKey: keys[1])
        defer {
            for (key, value) in zip(keys, saved) {
                if let value { defaults.set(value, forKey: key) } else { defaults.removeObject(forKey: key) }
            }
        }
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previousKeyWindow = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        let store = CityStore(storage: .init(
            read: { _ in throw CocoaError(.fileReadNoSuchFile) }, write: { _, _ in },
            sharedDefaults: { _ in nil }, reloadWidgets: {}))
        let host = UIHostingController(rootView: ThemedRootView().environmentObject(store))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true; previousKeyWindow?.makeKeyAndVisible() }
        for style in [UIUserInterfaceStyle.light, .dark, .light, .dark, .light] {
            window.overrideUserInterfaceStyle = style
            window.layoutIfNeeded()
            let expected = style == .dark ? [17, 18, 20] : [238, 238, 238]
            var color: [UInt8] = []
            // Wait for the asynchronous hosting/render transaction, rather than
            // sampling the previous frame on a busy simulator build machine.
            for _ in 0..<20 {
                try await Task.sleep(for: .milliseconds(100))
                let image = UIGraphicsImageRenderer(size: host.view.bounds.size).image { _ in
                    XCTAssertTrue(host.view.drawHierarchy(in: host.view.bounds, afterScreenUpdates: true))
                }
                // Unobstructed screen edge, away from quote, dial and glass.
                color = try pixel(image, at: CGPoint(x: 2, y: host.view.bounds.midY))
                if (0..<3).allSatisfy({ abs(Int(color[$0]) - expected[$0]) <= 1 }) { break }
            }
            for channel in 0..<3 { XCTAssertEqual(Int(color[channel]), expected[channel], accuracy: 1) }
        }
    }

    private func pixel(_ image: UIImage, at point: CGPoint) throws -> [UInt8] {
        let cg = try XCTUnwrap(image.cgImage)
        let crop = try XCTUnwrap(cg.cropping(to: CGRect(x: point.x * image.scale, y: point.y * image.scale, width: 1, height: 1)))
        var rgba = [UInt8](repeating: 0, count: 4)
        let context = try XCTUnwrap(CGContext(data: &rgba, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue))
        context.draw(crop, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        return rgba
    }

    func testManualModesIgnoreOppositeSystemTraits() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previousKeyWindow = scene.windows.first(where: \.isKeyWindow)
        defer { previousKeyWindow?.makeKeyAndVisible() }
        for preference in [AppAppearancePreference.light, .dark] {
            let window = UIWindow(windowScene: scene)
            var observed: (ColorScheme, Bool)?
            let host = UIHostingController(rootView: ThemedPaletteProbe { observed = ($0, $1) }
                .preferredColorScheme(preference.preferredColorSchemeOverride))
            window.rootViewController = host
            window.makeKeyAndVisible()
            defer { window.isHidden = true }
            for style in [UIUserInterfaceStyle.light, .dark, .light] {
                window.overrideUserInterfaceStyle = style
                window.layoutIfNeeded()
                try await Task.sleep(for: .milliseconds(200))
                let value = try XCTUnwrap(observed)
                XCTAssertEqual(value.0, preference.preferredColorSchemeOverride)
                XCTAssertEqual(value.1, preference == .dark)
            }
        }
    }

    func testExistingMapTraitObserversUpdateInPlace() async throws {
        let renderer = try NightRenderer()
        let overlay = DayNightOverlay(renderer: renderer, date: Date(timeIntervalSince1970: 1793250000))
        let controller = UIViewController()
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previousKeyWindow = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer { window.isHidden = true; previousKeyWindow?.makeKeyAndVisible() }
        controller.view.addSubview(overlay)
        // Camera setup activates the renderer's existing trait-dependent opacity.
        overlay.hasCamera = true
        for style in [UIUserInterfaceStyle.light, .dark, .light] {
            window.overrideUserInterfaceStyle = style
            window.layoutIfNeeded()
            try await Task.sleep(for: .milliseconds(100))
            XCTAssertEqual(overlay.uniforms.style.x, style == .dark ? 0.42 : overlay.lightModeMaximumOpacity, accuracy: 0.0001)
            let resolved = WorldMapMarkerLabel.fillColor.resolvedColor(with: overlay.traitCollection)
            XCTAssertEqual(resolved, style == .dark ? UIColor.white : UIColor.black)
        }
        overlay.suspend()
    }
}

private struct PaletteProbe: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appTheme) private var theme
    let report: (ColorScheme, Bool) -> Void

    var body: some View {
        ProbeBridge(scheme: colorScheme, isDark: theme.variant == .dark, report: report)
            .overlay { Text("Add").modifier(TopBarForegroundStyle()) }
            .background { AppScreenBackground() }
            .overlay(alignment: .bottom) { ProgressiveBottomBlurOverlay(height: 260) }
    }
}

private struct ProbeBridge: UIViewRepresentable {
    let scheme: ColorScheme
    let isDark: Bool
    let report: (ColorScheme, Bool) -> Void
    func makeUIView(context: Context) -> UIView { UIView() }
    func updateUIView(_ view: UIView, context: Context) { report(scheme, isDark) }
}

private struct ThemedPaletteProbe: View {
    @Environment(\.colorScheme) private var colorScheme
    let report: (ColorScheme, Bool) -> Void
    var body: some View {
        PaletteProbe(report: report)
            .environment(\.appTheme, AppTheme.forColorScheme(colorScheme))
    }
}
