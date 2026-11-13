import SwiftUI
import UIKit
import MessageUI

private enum RowTrailing {
    case text(String)
    case symbol(String)
}

private enum SettingsLinkAction {
    case appStoreReview
    case contactMe
    case shareApp
    case privacyPolicy
    case termsOfUse
    case dataAttribution
}

struct SettingsSheetView: View {
    var usesCompactHeader = false
    var presentingRailOnRight = true
    @State private var hinge: DuoHingeState.Status = .unavailable
    @State private var contentLayout = SettingsContentWidthObserver.Configuration()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.appTheme) private var theme
    @AppStorage(CityViewPreference.storageKey) private var cityViewPreferenceRawValue = CityViewPreference.basic.rawValue
    @AppStorage(AppTimeFormatPreference.storageKey) private var timeFormatPreferenceRawValue = AppTimeFormatPreference.system.rawValue
    @AppStorage(AppAppearancePreference.storageKey) private var appearancePreferenceRawValue = AppAppearancePreference.system.rawValue
    @State private var isMailComposerPresented = false
    @State private var isSharePresented = false
    @State private var presentedLegalDocument: LegalDocument?

    private var selectedCityViewPreference: CityViewPreference {
        CityViewPreference.from(rawValue: cityViewPreferenceRawValue)
    }

    private var selectedTimeFormatPreference: AppTimeFormatPreference {
        get { AppTimeFormatPreference.from(rawValue: timeFormatPreferenceRawValue) }
        set { timeFormatPreferenceRawValue = newValue.rawValue }
    }

    private var selectedAppearancePreference: AppAppearancePreference {
        AppAppearancePreference.from(rawValue: appearancePreferenceRawValue)
    }

    private var resolvedParallaxVariant: SettingsParallaxIllustrationView.Variant {
        let systemVariant: SettingsParallaxIllustrationView.Variant = theme.variant == .dark ? .dark : .light

        switch selectedAppearancePreference {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return systemVariant
        }
    }

    private var mailRecipient: String { "hi@sergy.xyz" }
    private var mailSubject: String { "Hours — Contact" }
    private let appStoreID = "6760683802"
    private var appStoreURL: URL {
        URL(string: "https://apps.apple.com/app/id\(appStoreID)")!
    }
    private var appStoreReviewURL: URL {
        URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review")!
    }
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
    }
    private var appBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
    }
    private var appearanceSettingDescription: String { selectedAppearancePreference.displayTitle }
    private var linkRows: [(title: String, trailing: RowTrailing, action: SettingsLinkAction)] {
        [
            (
                title: "Rate on the App Store",
                trailing: RowTrailing.text("ver \(appVersion).\(appBuild)"),
                action: .appStoreReview
            ),
            (
                title: "Contact me",
                trailing: RowTrailing.text("Any ideas?"),
                action: .contactMe
            ),
            (
                title: "Share with friends",
                trailing: RowTrailing.text("Spread the word"),
                action: .shareApp
            ),
            (
                title: "Privacy policy",
                trailing: RowTrailing.symbol("arrow.up.forward"),
                action: .privacyPolicy
            ),
            (
                title: "Terms of use",
                trailing: RowTrailing.symbol("arrow.up.forward"),
                action: .termsOfUse
            ),
            (
                title: "Data attribution",
                trailing: RowTrailing.symbol("chevron.right"),
                action: .dataAttribution
            )
        ]
    }
    private var mailBody: String {
        let locale = Locale.current.identifier
        let timeZone = TimeZone.current.identifier
        let iOSVersion = UIDevice.current.systemVersion
        let deviceModel = UIDevice.current.model
        let deviceName = UIDevice.current.name
        let hardwareIdentifier = Self.hardwareIdentifier() ?? "Unknown"

        return """
        Hello,

        [Write your message here]

        ---
        App: Hours
        Version: \(appVersion) (\(appBuild))
        iOS: \(iOSVersion)
        Device: \(deviceModel) (\(deviceName))
        Device Identifier: \(hardwareIdentifier)
        Locale: \(locale)
        Time Zone: \(timeZone)
        Time Format Setting: \(selectedTimeFormatPreference.displayTitle)
        Appearance Setting: \(appearanceSettingDescription)
        """
    }

    var body: some View {
        NavigationStack {
            mainContent(expandedEdges: [])
                .modifier(SettingsContentSafeArea(enabled: contentLayout.expandsContent,
                                                  railOnRight: contentLayout.isSplitView ? presentingRailOnRight : true))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    closeButton
                }
            }
            .modifier(SettingsToolbarPlacement(keepsTopHeader: contentLayout.isSplitView && !presentingRailOnRight))
        }
        .background {
            DuoHingeObserver { hinge = $0 }
            SettingsContentWidthObserver(hinge: hinge) { contentLayout = $0 }
        }
        // The root theme already resolves System. Passing its scheme explicitly
        // also clears a previous manual override on an already-presented sheet.
        .preferredColorScheme(theme.variant == .dark ? .dark : .light)
        .scrollBounceBehavior(.basedOnSize)
        .sheet(isPresented: $isMailComposerPresented) {
            MailComposeView(
                recipients: [mailRecipient],
                subject: mailSubject,
                messageBody: mailBody
            )
        }
        .sheet(isPresented: $isSharePresented) {
            ShareSheet(items: [appStoreURL])
        }
        .sheet(item: $presentedLegalDocument) { document in
            LegalDocumentSheet(document: document)
        }
    }


    private func mainContent(expandedEdges: Edge.Set) -> some View {
        ZStack {
            SheetStyle.appScreenBackground(for: theme)
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {

                    if usesCompactHeader {
                        compactHeader
                    } else {
                        VStack(spacing: -8) {
                            Text("Catch")
                            Text("the moment")
                            Text("in hours")
                        }
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(Color(red: 78.0 / 255.0, green: 80.0 / 255.0, blue: 89.0 / 255.0))
                        .tracking(-0.96)
                        .multilineTextAlignment(.center)
                        .padding(.top, -16)

                        heroSection
                            .padding(.top, -32)
                    }

                    settingsBlock
                        .padding(.top, usesCompactHeader ? 0 : 12)
                        .padding(.horizontal, 8)

                    linksBlock
                        .padding(.top, 8)
                        .padding(.horizontal, 8)

                    footer
                        .padding(.top, 56)
                        .padding(.bottom, 32)
                        .padding(.horizontal, 40)
                        .frame(maxWidth: .infinity)
                }
                .padding(.top, usesCompactHeader ? 0 : 32)
                .frame(maxWidth: .infinity, alignment: .top)
            }
            .scrollEdgeEffectStyle(.soft, for: .top)
            // Recover only the inset inside the assigned narrow Duo viewport.
            .ignoresSafeArea(.container, edges: expandedEdges)
        }
    }

    // Figma 718:10469: the title overlays the original artwork's transparent
    // upper area. Let the artwork establish the header height without clipping.
    private var compactHeader: some View {
        heroSection
            .frame(width: 532, height: 457.998)
            .frame(maxWidth: .infinity)
            .frame(height: 458, alignment: .top)
            .overlay(alignment: .top) {
                VStack(spacing: 0) {
                    Text("Catch the moment")
                        .frame(height: 32)
                    Text("in hours")
                        .frame(height: 32)
                }
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(Color(red: 78.0 / 255.0, green: 80.0 / 255.0, blue: 89.0 / 255.0))
                .tracking(-0.96)
                .multilineTextAlignment(.center)
                .frame(width: 377)
                .offset(x: -1, y: 5)
            }
    }

    private var heroSection: some View {
        SettingsParallaxIllustrationView(variant: resolvedParallaxVariant)
            .id("settings-parallax-\(resolvedParallaxVariant.rawValue)")
            .frame(maxWidth: .infinity)
            .accessibilityHidden(true)
            .frame(maxWidth: .infinity, alignment: .top)
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .medium))
        }
        .buttonStyle(.plain)
    }

    private var settingsBlock: some View {
        VStack(spacing: 1) {
            cityViewRow
                .background(preferencesBackground)
            appearanceRow
                .background(preferencesBackground)
            timeFormatRow
                .background(preferencesBackground)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var preferencesBackground: Color {
        SheetStyle.groupedRowBackground(for: theme).opacity(0.8)
    }

    private var cityViewRow: some View {
        SettingsPreferenceRow {
            ForEach(CityViewPreference.allCases, id: \.self) { preference in
                SettingsPreferenceOption(
                    title: preference.displayTitle,
                    isSelected: selectedCityViewPreference == preference,
                    preview: preference == .basic ? .basic : (preference == .compact ? .compact : .cards)
                ) {
                    cityViewPreferenceRawValue = preference.rawValue
                    triggerNotificationHaptic(.success)
                }
                .accessibilityIdentifier("settings.cityView.\(preference.rawValue)")
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 20)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("City view")
    }

    private var appearanceRow: some View {
        SettingsPreferenceRow {
            ForEach(AppAppearancePreference.allCases, id: \.self) { preference in
                SettingsPreferenceOption(
                    title: preference.displayTitle,
                    isSelected: selectedAppearancePreference == preference
                ) {
                    appearancePreferenceRawValue = preference.rawValue
                    triggerNotificationHaptic(.success)
                }
                .accessibilityIdentifier("settings.appearance.\(preference.rawValue)")
            }
        }
        .padding(8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Appearance")
    }

    private var displayedTimeFormatPreference: AppTimeFormatPreference {
        guard selectedTimeFormatPreference == .system else { return selectedTimeFormatPreference }
        // Reflect the existing formatter's system resolution without changing the saved value.
        let time = CityTimeFormatter.formatTimeComponents(Date(), in: .current)
        return time.meridiem == nil ? .twentyFourHour : .twelveHour
    }

    private var timeFormatRow: some View {
        SettingsPreferenceRow {
            ForEach([AppTimeFormatPreference.twentyFourHour, .twelveHour], id: \.self) { preference in
                SettingsPreferenceOption(
                    title: preference == .twentyFourHour ? "24-hour" : "12-hour",
                    isSelected: displayedTimeFormatPreference == preference
                ) {
                    timeFormatPreferenceRawValue = preference.rawValue
                    triggerNotificationHaptic(.success)
                }
                .accessibilityIdentifier("settings.timeFormat.\(preference.rawValue)")
            }
        }
        .padding(8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Time format")
    }

    private var linksBlock: some View {
        VStack(spacing: 1) {
            ForEach(Array(linkRows.enumerated()), id: \.offset) { index, row in
                let onTapHandler: (() -> Void)? = {
                    switch row.action {
                    case .appStoreReview:
                        openURL(appStoreReviewURL)
                    case .contactMe:
                        presentContactMe()
                    case .shareApp:
                        isSharePresented = true
                    case .privacyPolicy:
                        presentedLegalDocument = .privacy
                    case .termsOfUse:
                        presentedLegalDocument = .terms
                    case .dataAttribution:
                        presentedLegalDocument = .dataAttribution
                    }
                }

                SettingsLinkRow(
                    title: row.title,
                    trailing: row.trailing,
                    onTap: onTapHandler
                )
                    .background(groupedRowBackground(for: index, total: linkRows.count))
            }
        }
    }

    private func presentContactMe() {
        if MFMailComposeViewController.canSendMail() {
            isMailComposerPresented = true
            return
        }

        var components = URLComponents()
        components.scheme = "mailto"
        components.path = mailRecipient
        components.queryItems = [
            URLQueryItem(name: "subject", value: mailSubject),
            URLQueryItem(name: "body", value: mailBody)
        ]

        guard let url = components.url else { return }
        openURL(url)
    }

    private static func hardwareIdentifier() -> String? {
        var systemInfo = utsname()
        uname(&systemInfo)

        let identifier = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }

        let trimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func triggerNotificationHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    private var footer: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.gauge.open")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(theme.textSubdued)

            Text("Made by D.R.R.S.\nBacause I want it for a long time")
                .font(.system(size: 14, weight: .regular))
                .tracking(-0.42)
                .multilineTextAlignment(.center)
                .foregroundStyle(theme.textSubdued)

            Text("fortis imaginatio generat casum\n© 2026")
                .font(.system(size: 14, weight: .regular))
                .tracking(-0.42)
                .multilineTextAlignment(.center)
                .foregroundStyle(theme.textSubdued)
        }
    }

    @ViewBuilder
    private func groupedRowBackground(for index: Int, total: Int) -> some View {
        if total <= 1 {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(SheetStyle.groupedRowBackground(for: theme))
        } else if index == 0 {
            UnevenRoundedRectangle(
                cornerRadii: .init(topLeading: 24, bottomLeading: 0, bottomTrailing: 0, topTrailing: 24),
                style: .continuous
            )
            .fill(SheetStyle.groupedRowBackground(for: theme))
        } else if index == total - 1 {
            UnevenRoundedRectangle(
                cornerRadii: .init(topLeading: 0, bottomLeading: 24, bottomTrailing: 24, topTrailing: 0),
                style: .continuous
            )
            .fill(SheetStyle.groupedRowBackground(for: theme))
        } else {
            Rectangle()
                .fill(SheetStyle.groupedRowBackground(for: theme))
        }
    }
}

private struct SettingsPreferenceRow<Content: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ViewBuilder let content: Content

    var body: some View {
        // Keep enlarged labels readable without shrinking text or changing the sheet width.
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 4))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 4))
        layout { content }
    }
}

// Custom Figma controls: native segmented pickers have different geometry and surfaces.
private struct SettingsPreferenceOption: View {
    enum Preview {
        case basic, compact, cards
    }

    @Environment(\.appTheme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var fontSize = 16.0
    let title: String
    let isSelected: Bool
    var preview: Preview? = nil
    let action: () -> Void

    // Figma 723:15345 uses a brighter orange than the app-wide accent.
    private let selectionAccent = Color(red: 1, green: 64.0 / 255.0, blue: 0)
    private var neutral: Color { theme.variant == .dark ? .white : .black }
    private var labelColor: Color {
        isSelected ? (theme.variant == .dark ? theme.textPrimary : .black) : neutral.opacity(0.3)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                if let preview {
                    layoutPreview(preview)
                        .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? 85.333 : nil)
                        .padding(.horizontal, 16)
                        .accessibilityHidden(true)
                }

                Text(title)
                    .font(.system(size: fontSize, weight: isSelected ? .medium : .regular))
                    .tracking(-0.03 * fontSize)
                    .foregroundStyle(labelColor)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight: 20)
                    .padding(.horizontal, preview == nil ? 16 : 0)

                if preview != nil {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .symbolRenderingMode(.palette)
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(isSelected ? .white : neutral.opacity(0.2), selectionAccent)
                        .frame(height: 20)
                        .accessibilityHidden(true)
                }
            }
            .padding(.vertical, preview == nil ? 10 : 0)
            .frame(maxWidth: .infinity, minHeight: preview == nil ? 48 : nil)
            .background {
                if preview == nil && isSelected {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(theme.surfaceControl)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(SettingsPreferenceButtonStyle())
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func layoutPreview(_ preview: Preview) -> some View {
        VStack(spacing: 2) {
            ForEach(0..<(preview == .compact ? 3 : 2), id: \.self) { _ in
                HStack(spacing: 2) {
                    ForEach(0..<(preview == .cards ? 2 : 1), id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(isSelected ? selectionAccent.opacity(0.2) : neutral.opacity(0.05))
                    }
                }
            }
        }
        .padding(2)
        .frame(height: 72)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? selectionAccent.opacity(0.1) : neutral.opacity(0.03))
        )
    }
}

// Figma already specifies the muted Cards colors; avoid native disabled dimming on top.
private struct SettingsPreferenceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No-op
    }
}

private struct SettingsLinkRow: View {
    @Environment(\.appTheme) private var theme
    let title: String
    let trailing: RowTrailing?
    let onTap: (() -> Void)?

    @ViewBuilder
    private var rowContent: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .regular))
                .tracking(-0.48)
                .foregroundStyle(theme.textPrimary)

            Spacer(minLength: 0)

            if let trailing {
                switch trailing {
                case .text(let value):
                    Text(value)
                        .font(.system(size: 16, weight: .regular))
                        .tracking(-0.48)
                        .foregroundStyle(theme.textSubdued)
                case .symbol(let name):
                    Image(systemName: name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(theme.textSubdued)
                }
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 64)
    }

    var body: some View {
        if let onTap {
            Button(action: onTap) {
                rowContent
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
        } else {
            rowContent
        }
    }
}

private struct MailComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let subject: String
    let messageBody: String

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        controller.setToRecipients(recipients)
        controller.setSubject(subject)
        controller.setMessageBody(messageBody, isHTML: false)
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
        // No-op
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            controller.dismiss(animated: true)
        }
    }
}

/// Uses the existing hinge observer and the same window/screen classification
/// as City Details. Recover the actual inset of either Split View pane.
private struct SettingsContentWidthObserver: UIViewRepresentable {
    let hinge: DuoHingeState.Status
    struct Configuration: Equatable {
        var expandsContent = false
        var isSplitView = false
    }

    let changed: (Configuration) -> Void

    static func configuration(hinge: DuoHingeState.Status, window: CGSize, screen: CGSize) -> Configuration {
        let isSplit = (hinge == .fullyOpen || hinge == .partiallyOpen) && screen.width > screen.height &&
            window.width < screen.width - 1 && abs(window.height - screen.height) < 1
        return Configuration(expandsContent: hinge == .closed || isSplit, isSplitView: isSplit)
    }

    func makeUIView(context: Context) -> ObserverView { ObserverView() }

    func updateUIView(_ view: ObserverView, context: Context) {
        view.hinge = hinge
        view.changed = changed
        view.scheduleUpdate()
    }

    final class ObserverView: UIView {
        var hinge: DuoHingeState.Status = .unavailable
        var changed: ((Configuration) -> Void)?
        private var lastValue: Configuration?
        private var pending = false

        override func didMoveToWindow() { super.didMoveToWindow(); scheduleUpdate() }
        override func layoutSubviews() { super.layoutSubviews(); scheduleUpdate() }
        override func safeAreaInsetsDidChange() { super.safeAreaInsetsDidChange(); scheduleUpdate() }

        func scheduleUpdate() {
            guard !pending else { return }
            pending = true
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                pending = false
                guard let window, let scene = window.windowScene else { return }
                let value = SettingsContentWidthObserver.configuration(
                    hinge: hinge, window: window.bounds.size, screen: scene.screen.bounds.size)
                guard value != lastValue else { return }
                lastValue = value
                changed?(value)
            }
        }
    }
}

/// Only left Split View needs the half-open top-header override. On the
/// status-bearing right pane, native automatic placement avoids a top gutter.
private struct SettingsToolbarPlacement: ViewModifier {
    let keepsTopHeader: Bool

    func body(content: Content) -> some View {
        if #available(iOS 27.1, *) {
            content.toolbarVerticalBehavior(keepsTopHeader ? .disabled : .automatic)
        } else {
            content
        }
    }
}

/// Use the presenting window's rail side. Reading toolbarVerticalEdge here
/// would feed the result of our toolbar override back into its own placement.
private struct SettingsContentSafeArea: ViewModifier {
    @Environment(\.layoutDirection) private var layoutDirection
    let enabled: Bool
    var railOnRight = true

    func body(content: Content) -> some View {
        let trailing = railOnRight == (layoutDirection == .leftToRight)
        content.ignoresSafeArea(.container, edges: enabled ? (trailing ? .trailing : .leading) : [])
    }
}
