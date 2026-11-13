import XCTest
import SwiftUI
import Vision
@testable import MapHarness

@MainActor final class CityDetailsSafeAreaTests: XCTestCase {
    func testOnlyClosedAndSideBySideInnerWindowsExpandContent() {
        let landscape = CGSize(width: 951, height: 669)
        let portrait = CGSize(width: 669, height: 951)
        for hinge: DuoHingeState.Status in [.unavailable, .closed, .partiallyOpen, .fullyOpen] {
            for (window, screen, split) in [
                (landscape, landscape, false), (portrait, portrait, false),
                (CGSize(width: 469, height: 669), landscape, true),
                (CGSize(width: 469, height: 334), landscape, false),
                (CGSize(width: 466, height: 678), CGSize(width: 466, height: 678), false)
            ] {
                let layout = CityDetailsLayoutObserver.configuration(hinge: hinge, window: window, screen: screen)
                XCTAssertEqual(layout.isInnerSplitView, hinge != .unavailable && hinge != .closed && split)
                XCTAssertEqual(layout.expandsContentSafeArea,
                    hinge == .closed || (hinge != .unavailable && split), "\(hinge), \(window), \(screen)")
            }
        }
    }

    func testExpandedCardRowsAndLongDescriptionsRemainComplete() throws {
        let city = City(name: "San Fernando del Valle de Catamarca", timeZoneID: "America/Argentina/Catamarca")
        let date = ISO8601DateFormatter().date(from: "2026-11-13T15:59:00Z")!
        for width: CGFloat in [450, 453] {
            for dark in [false, true] {
                for time in ["12:59 PM", "12:59"] {
                    for unavailable in [false, true] {
                        let details = CityDetailsView(
                            weatherCardState: unavailable ? .error : .loaded(.init(title: "Cloudy", value: "33°C", secondary: "Feels like 37°C", symbolName: "cloud.fill")),
                            sunCardState: unavailable ? .error : .loaded(.init(title: "Sunset", value: time, secondary: "Sunrise at 06:17 AM", symbolName: "sunset.fill")),
                            city: city, primaryCity: City(name: "Bangkok", timeZoneID: "Asia/Bangkok"),
                            date: date, relativeOffsetMinutes: 0, cityViewPreference: .basic)
                        for type in [DynamicTypeSize.large, .accessibility5] {
                            let renderer = ImageRenderer(content: HStack(spacing: 8) { details.weatherCard; details.sunCard }
                                .environment(\.appTheme, dark ? .dark : .light)
                                .environment(\.colorScheme, dark ? .dark : .light)
                                .environment(\.dynamicTypeSize, type))
                            renderer.proposedSize = .init(width: width - 16, height: nil); renderer.scale = 3
                            let image = try XCTUnwrap(renderer.uiImage)
                            XCTAssertEqual(image.size.height, 157, accuracy: 0.5)
                            let request = VNRecognizeTextRequest(); request.recognitionLevel = .accurate
                            try VNImageRequestHandler(cgImage: XCTUnwrap(image.cgImage)).perform([request])
                            let words = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
                            XCTAssertFalse(words.contains("…"), words)
                            XCTAssertTrue(words.contains(unavailable ? "off duty" : "12:59"), words)
                        }
                        let description = ImageRenderer(content: details.overlapText
                            .environment(\.appTheme, dark ? .dark : .light).padding(.horizontal, 32))
                        description.proposedSize = .init(width: width, height: nil); description.scale = 3
                        let request = VNRecognizeTextRequest(); request.recognitionLevel = .accurate
                        try VNImageRequestHandler(cgImage: XCTUnwrap(description.cgImage)).perform([request])
                        let words = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
                        XCTAssertTrue(words.contains("Catamarca"), words)
                        XCTAssertTrue(words.contains("Bangkok"), words)
                    }
                }
            }
        }
    }

    func testSplitToolbarKeepsCloseLeftAndCalendarRightInBothThemes() async throws {
        guard #available(iOS 27.1, *) else { throw XCTSkip("Duo toolbar behavior requires iOS 27.1") }
        for scheme in [ColorScheme.light, .dark] {
            let state = SafeAreaFixtureState()
            state.expanded = true
            state.keepsTopCorners = true
            let host = UIHostingController(rootView: SafeAreaFixture(state: state).environment(\.colorScheme, scheme))
            let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
            let previousKeyWindow = scene.windows.first(where: \.isKeyWindow)
            let window = UIWindow(windowScene: scene)
            window.frame = CGRect(x: 0, y: 0, width: 469, height: 669)
            window.rootViewController = host; window.makeKeyAndVisible()
            defer { previousKeyWindow?.makeKey() }
            defer { window.isHidden = true }
            host.view.frame = window.bounds; host.view.layoutIfNeeded()
            try await Task.sleep(for: .milliseconds(200))
            let closeView = try XCTUnwrap(state.controlViews["close"]?.first { $0.window === window && !$0.bounds.isEmpty })
            let calendarView = try XCTUnwrap(state.controlViews["calendar"]?.first { $0.window === window && !$0.bounds.isEmpty })
            let close = closeView.convert(closeView.bounds, to: window)
            let calendar = calendarView.convert(calendarView.bounds, to: window)
            XCTAssertEqual(close.midY, calendar.midY, accuracy: 0.5)
            XCTAssertLessThan(close.midX, host.view.bounds.midX)
            XCTAssertGreaterThan(calendar.midX, host.view.bounds.midX)
            XCTAssertGreaterThanOrEqual(close.minX, 0)
            XCTAssertLessThanOrEqual(calendar.maxX, host.view.bounds.maxX)
            XCTAssertEqual(close.size, calendar.size)
        }
    }

    func testContentUsesPresentingRailInsetAndLeavesToolbarUnchanged() async throws {
        for direction in [LayoutDirection.leftToRight, .rightToLeft] {
            for (leftInset, rightInset, railOnRight): (CGFloat, CGFloat, Bool) in [(13, 0, true), (13, 40, true), (13, 84, true), (76, 0, false)] {
                let state = SafeAreaFixtureState()
                state.railOnRight = railOnRight
                let host = UIHostingController(rootView: SafeAreaFixture(state: state).environment(\.layoutDirection, direction))
                host.additionalSafeAreaInsets = .init(top: 19, left: leftInset, bottom: 34, right: rightInset)
                let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 466, height: 678))
                window.rootViewController = host; window.isHidden = false
                defer { window.isHidden = true }
                host.view.frame = window.bounds
                host.view.setNeedsLayout(); host.view.layoutIfNeeded()
                try await Task.sleep(for: .milliseconds(200))
                let before = try XCTUnwrap(state.frames["content"])
                let close = try XCTUnwrap(state.frames["close"])
                let calendar = try XCTUnwrap(state.frames["calendar"])
                let inset = railOnRight ? host.view.bounds.maxX - before.maxX : before.minX
                state.expanded = true
                try await Task.sleep(for: .milliseconds(200))
                host.view.layoutIfNeeded()
                let after = try XCTUnwrap(state.frames["content"])
                XCTAssertEqual(after.minX, railOnRight ? before.minX : 0, accuracy: 0.5, "Recover only the presenting rail inset")
                XCTAssertEqual(after.width, before.width + inset, accuracy: 0.5)
                XCTAssertEqual(after.minY, before.minY, accuracy: 0.5)
                XCTAssertEqual(after.height, before.height, accuracy: 0.5)
                XCTAssertLessThanOrEqual(after.maxX, host.view.bounds.maxX + 0.5, "Stay inside the assigned viewport")
                XCTAssertEqual(state.frames["close"], close)
                XCTAssertEqual(state.frames["calendar"], calendar)
            }
        }
    }
}

@MainActor private final class SafeAreaFixtureState: ObservableObject {
    @Published var expanded = false
    var keepsTopCorners = false
    var railOnRight = true
    var frames: [String: CGRect] = [:]
    var controlViews: [String: [UIView]] = [:]
}

private struct SafeAreaFixture: View {
    @ObservedObject var state: SafeAreaFixtureState
    var body: some View {
        NavigationStack {
            GeometryReader { _ in
                Color.clear
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { state.frames["content"] = $0 }
            }
            .modifier(CityDetailsContentSafeArea(enabled: state.expanded, railOnRight: state.railOnRight))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { control("close", symbol: "xmark") }
                ToolbarItem(placement: .topBarTrailing) { control("calendar", symbol: "calendar.badge.plus") }
            }
            .modifier(CityDetailsToolbarPlacement(keepsTopCorners: state.keepsTopCorners))
        }
    }
    private func control(_ key: String, symbol: String) -> some View {
        Button {} label: {
            Image(systemName: symbol).frame(width: 32, height: 32)
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { state.frames[key] = $0 }
                .background {
                    if state.keepsTopCorners {
                        ToolbarControlProbe { state.controlViews[key, default: []].append($0) }
                    }
                }
        }
    }
}

/// Toolbar labels have separate SwiftUI coordinate roots; measure in the window.
private struct ToolbarControlProbe: UIViewRepresentable {
    let capture: (UIView) -> Void
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        capture(view)
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}
