import SwiftUI
import UIKit

struct AddCitySheetView: View {
    let existingCanonicalIDs: Set<String>
    let onSelect: (CitySearchItem) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale
    @Environment(\.appTheme) private var theme
    @State private var query = ""
    @State private var results: [CitySearchItem] = []
    @State private var searchPhase: SearchPhase = .idle
    @State private var searchTask: Task<Void, Never>?
    @State private var isSearchFieldFocused = false
    @State private var selectedUTCOffset = CustomReferenceOffsetOption.zero(for: .utc)
    @State private var selectedGMTOffset = CustomReferenceOffsetOption.zero(for: .gmt)
    @State private var activeCustomReferenceSelector: ActiveCustomReferenceSelector?
    @StateObject private var currentLocationProvider = CurrentLocationCityProvider()

    private enum ActiveCustomReferenceSelector: String, Identifiable {
        case utc
        case gmt

        var id: String { rawValue }

        var kind: CitySearchItem.SpecialReferenceKind {
            switch self {
            case .utc:
                return .utc
            case .gmt:
                return .gmt
            }
        }
    }

    private struct DisplayResult: Identifiable {
        let item: CitySearchItem?
        let isCurrentLocation: Bool

        var id: String {
            if isCurrentLocation {
                return "current-location-row"
            }
            return "city-result-\(item?.canonicalIdentity ?? "unknown")"
        }
    }

    private struct DisplaySection: Identifiable {
        let id: String
        let results: [DisplayResult]
    }

    private enum SearchPhase {
        case idle
        case searching
        case completed
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var emptyStateTitle: String {
        "No results for \"\(trimmedQuery)\""
    }

    private var isShowingEmptySearchState: Bool {
        !trimmedQuery.isEmpty &&
            searchPhase == .completed &&
            results.isEmpty
    }

    private var isSearchingQuery: Bool {
        !trimmedQuery.isEmpty && searchPhase == .searching
    }

    private var rowSeparatorHeight: CGFloat {
        3 / max(displayScale, 1)
    }

    private var displayedSections: [DisplaySection] {
        let mappedResults = results.map { DisplayResult(item: $0, isCurrentLocation: false) }

        guard trimmedQuery.isEmpty else {
            return [DisplaySection(id: "search-results", results: mappedResults)]
        }

        var primaryResults: [DisplayResult] = []
        if currentLocationProvider.permissionState == .authorized {
            primaryResults.append(
                DisplayResult(item: currentLocationProvider.currentCityItem, isCurrentLocation: true)
            )
        }
        let referenceItems = CitySearchProvider.shared.referenceItemsForZeroState()
        primaryResults.append(contentsOf: referenceItems.map { DisplayResult(item: $0, isCurrentLocation: false) })

        let secondaryResults = CitySearchProvider.shared
            .popularCitiesForZeroState()
            .map { DisplayResult(item: $0, isCurrentLocation: false) }

        var sections: [DisplaySection] = []
        if !primaryResults.isEmpty {
            sections.append(DisplaySection(id: "zero-state-primary", results: primaryResults))
        }
        if !secondaryResults.isEmpty {
            sections.append(DisplaySection(id: "zero-state-secondary", results: secondaryResults))
        }

        return sections
    }

    var body: some View {
        let referenceDate = Date()
        let visibleSections = displayedSections

        NavigationStack {
            List {
                ForEach(Array(visibleSections.enumerated()), id: \.element.id) { sectionIndex, section in
                    ForEach(Array(section.results.enumerated()), id: \.element.id) { rowIndex, displayResult in
                        let item = displayResult.item
                        let resolvedItem = resolvedItem(for: item)
                        let isCurrentLocationRow = displayResult.isCurrentLocation
                        let isLocationLoadingRow = isCurrentLocationRow && item == nil
                        let isAlreadyAdded = resolvedItem.map { existingCanonicalIDs.contains($0.canonicalIdentity) } ?? false

                        rowView(
                            item: item,
                            resolvedItem: resolvedItem,
                            isCurrentLocationRow: isCurrentLocationRow,
                            isLocationLoadingRow: isLocationLoadingRow,
                            isAlreadyAdded: isAlreadyAdded,
                            referenceDate: referenceDate,
                            rowIndex: rowIndex,
                            totalRows: section.results.count
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }

                    if sectionIndex < visibleSections.count - 1 {
                        let nextSection = visibleSections[sectionIndex + 1]
                        if section.id == "zero-state-primary" && nextSection.id == "zero-state-secondary" {
                            popularCitiesLabelRow
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        } else {
                            Color.clear
                                .frame(height: 8)
                                .environment(\.defaultMinListRowHeight, 8)
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                    }
                }
            }
            .environment(\.defaultMinListRowHeight, 0)
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(SheetStyle.appScreenBackground(for: theme))
            .padding(.horizontal, 8)
            .navigationTitle("Add City")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .buttonStyle(.plain)
                }
            }
            .overlay {
                if isShowingEmptySearchState {
                    AddCityEmptyStateView(title: emptyStateTitle)
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomSearchArea
            }
        }
        .background(SheetStyle.appScreenBackground(for: theme).ignoresSafeArea())
        .onAppear {
            performSearch(for: query)
            currentLocationProvider.requestCurrentCity()
            DispatchQueue.main.async {
                isSearchFieldFocused = true
            }
        }
        .onChange(of: query) { _, newQuery in
            performSearch(for: newQuery)
            if newQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                currentLocationProvider.requestCurrentCity()
            }
        }
        .onDisappear {
            searchTask?.cancel()
            isSearchFieldFocused = false
        }
        .sheet(item: $activeCustomReferenceSelector) { selector in
            CustomReferenceOffsetSelectorSheet(
                title: "Select \(selector.kind.family.code) Offset",
                options: CustomReferenceOffsetOption.supportedOptions(for: selector.kind.family),
                selectedOption: selectedOffset(for: selector.kind),
                onSelect: { option in
                    updateSelectedOffset(option)
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.hidden)
        }
    }

    private var bottomSearchArea: some View {
        GlassEffectContainer(spacing: 10) {
            NativeBottomSearchTextField(
                text: $query,
                isFocused: $isSearchFieldFocused,
                placeholder: "Search",
                isSearching: isSearchingQuery
            )
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .glassEffect(.regular, in: Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

    private var popularCitiesLabelRow: some View {
        HStack {
            Text("Popular cities")
                .font(.system(size: 14))
                .tracking(-0.42)
                .foregroundStyle(theme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func performSearch(for query: String) {
        searchTask?.cancel()

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            results = []
            searchPhase = .idle
            return
        }

        let local = CitySearchProvider.shared.localResults(
            matching: query,
            excluding: []
        )
        results = local

        let shouldFetchFallback = CitySearchProvider.shared.shouldFetchFallback(
            for: query,
            localResultCount: local.count
        )

        if !local.isEmpty {
            searchPhase = .completed

            guard shouldFetchFallback else { return }

            searchTask = Task {
                let merged = await CitySearchProvider.shared.fallbackMergedResults(
                    matching: query,
                    localResults: local,
                    excluding: []
                )

                guard !Task.isCancelled else { return }
                guard self.query == query else { return }

                await MainActor.run {
                    results = merged
                }
            }
            return
        }

        searchPhase = .searching

        guard shouldFetchFallback else {
            searchTask = Task {
                try? await Task.sleep(for: .milliseconds(250))

                guard !Task.isCancelled else { return }
                guard self.query == query else { return }

                await MainActor.run {
                    searchPhase = .completed
                }
            }
            return
        }

        searchTask = Task {
            let merged = await CitySearchProvider.shared.fallbackMergedResults(
                matching: query,
                localResults: local,
                excluding: []
            )

            guard !Task.isCancelled else { return }
            guard self.query == query else { return }

            await MainActor.run {
                results = merged
                searchPhase = .completed
            }
        }
    }

    @ViewBuilder
    private func rowBackground(for index: Int, total: Int) -> some View {
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

    private func utcOffsetText(for timeZoneIdentifier: String, referenceDate: Date) -> String {
        guard let timeZone = TimeZone.hoursResolved(identifier: timeZoneIdentifier) else {
            return "UTC"
        }

        let seconds = timeZone.secondsFromGMT(for: referenceDate)
        let sign = seconds >= 0 ? "+" : "−"
        let absoluteSeconds = abs(seconds)
        let hours = absoluteSeconds / 3600
        let minutes = (absoluteSeconds % 3600) / 60

        if minutes == 0 {
            return "UTC\(sign)\(hours)"
        }

        return "UTC\(sign)\(hours):" + String(format: "%02d", minutes)
    }

    private func rowPrimaryText(for item: CitySearchItem?, isCurrentLocationLoadingRow: Bool) -> String {
        if isCurrentLocationLoadingRow {
            return "My location is ..."
        }

        guard let item else { return "" }
        if let specialReferenceKind = item.specialReferenceKind {
            return specialReferenceKind.descriptiveName
        }
        if item.country.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return item.city
        }
        return "\(item.city), \(item.country)"
    }

    private func rowLabelKind(
        for item: CitySearchItem?,
        isCurrentLocationRow: Bool,
        isAlreadyAdded: Bool,
        referenceDate: Date
    ) -> CitySearchRowLabel.Kind {
        if isCurrentLocationRow {
            if item == nil {
                return .locationLoading
            }
            return .myLocation
        }
        guard let item else {
            return .none
        }
        if isAlreadyAdded {
            return .added
        }
        return .utc(utcOffsetText(for: item.timeZoneIdentifier, referenceDate: referenceDate))
    }

    private func selectedOffset(for specialReferenceKind: CitySearchItem.SpecialReferenceKind) -> CustomReferenceOffsetOption {
        switch specialReferenceKind {
        case .utc:
            return selectedUTCOffset
        case .gmt:
            return selectedGMTOffset
        }
    }

    private func updateSelectedOffset(_ option: CustomReferenceOffsetOption) {
        switch option.family {
        case .utc:
            selectedUTCOffset = option
        case .gmt:
            selectedGMTOffset = option
        }
    }

    private func resolvedItem(for item: CitySearchItem?) -> CitySearchItem? {
        guard let item else { return nil }
        guard let specialReferenceKind = item.specialReferenceKind else { return item }

        let option = selectedOffset(for: specialReferenceKind)
        return CitySearchItem(
            id: option.canonicalID,
            city: option.cityName,
            country: "",
            timeZoneIdentifier: option.timeZoneIdentifier,
            aliases: item.aliases,
            canonicalID: option.canonicalID,
            specialReferenceKind: specialReferenceKind
        )
    }

    private func handleSelection(of item: CitySearchItem?, isAlreadyAdded: Bool) {
        searchTask?.cancel()

        guard let item else { return }

        guard !isAlreadyAdded else {
            dismiss()
            return
        }

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        onSelect(item)
        dismiss()
    }

    @ViewBuilder
    private func rowView(
        item: CitySearchItem?,
        resolvedItem: CitySearchItem?,
        isCurrentLocationRow: Bool,
        isLocationLoadingRow: Bool,
        isAlreadyAdded: Bool,
        referenceDate: Date,
        rowIndex: Int,
        totalRows: Int
    ) -> some View {
        let primaryText = rowPrimaryText(for: item, isCurrentLocationLoadingRow: isLocationLoadingRow)

        if let specialReferenceKind = item?.specialReferenceKind, !isCurrentLocationRow {
            HStack(alignment: .center, spacing: 16) {
                Button {
                    handleSelection(of: resolvedItem, isAlreadyAdded: isAlreadyAdded)
                } label: {
                    Text(primaryText)
                        .font(.system(size: 16, weight: .medium))
                        .tracking(-0.48)
                        .foregroundStyle(theme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())

                customReferenceMenu(for: specialReferenceKind)
            }
            .padding(.leading, 20)
            .padding(.trailing, 8)
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
            .background(rowBackground(for: rowIndex, total: totalRows))
            .padding(.bottom, rowIndex == totalRows - 1 ? 0 : rowSeparatorHeight)
        } else {
            Button {
                handleSelection(of: resolvedItem, isAlreadyAdded: isAlreadyAdded)
            } label: {
                HStack(alignment: .center, spacing: 16) {
                    Text(primaryText)
                        .font(.system(size: 16, weight: .medium))
                        .tracking(-0.48)
                        .foregroundStyle(theme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .opacity(isLocationLoadingRow ? 0.2 : 1)
                        .modifier(LocationPlaceholderShimmer(isActive: isLocationLoadingRow))

                    Spacer(minLength: 0)

                    CitySearchRowLabel(
                        kind: rowLabelKind(
                            for: item,
                            isCurrentLocationRow: isCurrentLocationRow,
                            isAlreadyAdded: isAlreadyAdded,
                            referenceDate: referenceDate
                        )
                    )
                }
                .padding(.leading, 20)
                .padding(.trailing, 8)
                .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                .background(rowBackground(for: rowIndex, total: totalRows))
                .padding(.bottom, rowIndex == totalRows - 1 ? 0 : rowSeparatorHeight)
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
        }
    }

    private func customReferenceMenu(for specialReferenceKind: CitySearchItem.SpecialReferenceKind) -> some View {
        let selectedOption = selectedOffset(for: specialReferenceKind)

        return Button {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            activeCustomReferenceSelector = specialReferenceKind == .utc ? .utc : .gmt
        } label: {
            HStack(spacing: 4) {
                Text(selectedOption.selectionLabel)
                    .font(.system(size: 16, weight: .medium))
                    .tracking(-0.48)
                    .foregroundStyle(theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(theme.tagNeutralText)
            }
            .padding(.leading, 16)
            .padding(.trailing, 12)
            .frame(height: 48)
            .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(theme.surfaceControl)
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

}

private struct CustomReferenceOffsetSelectorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale
    @Environment(\.appTheme) private var theme

    let title: String
    let options: [CustomReferenceOffsetOption]
    let selectedOption: CustomReferenceOffsetOption
    let onSelect: (CustomReferenceOffsetOption) -> Void

    private var rowSeparatorHeight: CGFloat {
        3 / max(displayScale, 1)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        onSelect(option)
                        dismiss()
                    } label: {
                        HStack(spacing: 16) {
                            Text(option.selectionLabel)
                                .font(.system(size: 16, weight: .medium))
                                .tracking(-0.48)
                                .foregroundStyle(theme.textPrimary)
                                .lineLimit(1)

                            Spacer(minLength: 0)

                            if option == selectedOption {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(theme.tagNeutralText)
                            }
                        }
                        .padding(.leading, 20)
                        .padding(.trailing, 20)
                        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                        .background(rowBackground(for: index, total: options.count))
                        .padding(.bottom, index == options.count - 1 ? 0 : rowSeparatorHeight)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
            .environment(\.defaultMinListRowHeight, 0)
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(SheetStyle.appScreenBackground(for: theme))
            .padding(.horizontal, 8)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .background(SheetStyle.appScreenBackground(for: theme).ignoresSafeArea())
    }

    @ViewBuilder
    private func rowBackground(for index: Int, total: Int) -> some View {
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

private struct LocationPlaceholderShimmer: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .overlay {
                if isActive {
                    GeometryReader { proxy in
                        let width = max(proxy.size.width, 1)
                        TimelineView(.animation) { timeline in
                            let duration = 1.4
                            let progress = timeline.date.timeIntervalSinceReferenceDate
                                .truncatingRemainder(dividingBy: duration) / duration
                            let offset = CGFloat(progress) * width * 2.2 - width * 1.1

                            LinearGradient(
                                colors: [
                                    .clear,
                                    Color.white.opacity(0.35),
                                    .clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: width * 0.85, height: proxy.size.height)
                            .offset(x: offset)
                        }
                    }
                    .mask(content)
                    .allowsHitTesting(false)
                }
            }
    }
}

private struct AddCityEmptyStateView: View {
    @Environment(\.appTheme) private var theme
    let title: String

    private var subtitle: String {
        "Check the spelling or try new search"
    }

    var body: some View {
        VStack(spacing: 0) {

            Image("AddCityEmptyStateIllustration")
                .resizable()
                .scaledToFit()
                .frame(width: 340, height: 262)
                .padding(.bottom, -80)

            VStack(spacing: 10) {

                Text(title)
                    .font(.system(size: 32, weight: .semibold))
                    .tracking(-0.96)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(theme.textSecondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .tracking(-0.42)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(theme.textSecondary)

            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 48)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .allowsHitTesting(false)
    }
}

private struct CitySearchRowLabel: View {
    @Environment(\.appTheme) private var theme
    enum Kind {
        case none
        case locationLoading
        case myLocation
        case added
        case referenceDescription(String)
        case utc(String)
    }

    let kind: Kind

    private var text: String {
        switch kind {
        case .none:
            return ""
        case .locationLoading:
            return ""
        case .myLocation:
            return "My location"
        case .added:
            return "Added"
        case .referenceDescription(let text):
            return text
        case .utc(let offset):
            return offset
        }
    }

    private var textColor: Color {
        switch kind {
        case .none:
            return .clear
        case .locationLoading:
            return theme.tagNeutralText
        case .added:
            return theme.tagAddedText
        case .myLocation, .referenceDescription, .utc:
            return theme.tagNeutralText
        }
    }

    private var backgroundColor: Color {
        switch kind {
        case .none:
            return theme.tagNeutralBackground
        case .locationLoading:
            return theme.tagNeutralBackground
        case .added:
            return theme.tagAddedBackground
        case .myLocation, .referenceDescription, .utc:
            return theme.tagNeutralBackground
        }
    }

    private var borderColor: Color {
        switch kind {
        case .none:
            return .clear
        case .locationLoading:
            return theme.separatorSoft
        case .added:
            return .clear
        case .myLocation, .referenceDescription, .utc:
            return theme.separatorSoft
        }
    }

    @ViewBuilder
    var body: some View {
        if case .none = kind {
            EmptyView()
        } else if case .locationLoading = kind {
            ProgressView()
                .progressViewStyle(.circular)
                .controlSize(.small)
                .padding(.horizontal, 16)
                .frame(minWidth: 48, minHeight: 48)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(backgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(borderColor, lineWidth: 1)
                )
        } else {
            Text(text)
                .font(.system(size: 16, weight: .regular))
                .tracking(-0.48)
                .foregroundStyle(textColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 16)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(backgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(borderColor, lineWidth: 1)
                )
        }
    }
}

private struct NativeBottomSearchTextField: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    let placeholder: String
    let isSearching: Bool

    func makeUIView(context: Context) -> UISearchTextField {
        let textField = UISearchTextField(frame: .zero)
        textField.delegate = context.coordinator
        textField.placeholder = placeholder
        textField.returnKeyType = .search
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .words
        textField.clearButtonMode = .whileEditing
        textField.adjustsFontForContentSizeCategory = true
        textField.borderStyle = .none
        textField.backgroundColor = .clear
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textDidChange(_:)), for: .editingChanged)
        context.coordinator.defaultLeftView = textField.leftView
        context.coordinator.defaultLeftViewMode = textField.leftViewMode
        return textField
    }

    func updateUIView(_ uiView: UISearchTextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        if uiView.placeholder != placeholder {
            uiView.placeholder = placeholder
        }

        context.coordinator.updateLeadingAccessory(for: uiView, isSearching: isSearching)

        if isFocused {
            guard !uiView.isFirstResponder else { return }
            DispatchQueue.main.async {
                uiView.becomeFirstResponder()
            }
        } else if uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, isFocused: $isFocused)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        @Binding private var text: String
        @Binding private var isFocused: Bool
        var defaultLeftView: UIView?
        var defaultLeftViewMode: UITextField.ViewMode = .always
        let loadingIndicator: UIActivityIndicatorView = {
            let indicator = UIActivityIndicatorView(style: .medium)
            indicator.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            indicator.hidesWhenStopped = true
            return indicator
        }()

        init(text: Binding<String>, isFocused: Binding<Bool>) {
            _text = text
            _isFocused = isFocused
        }

        func updateLeadingAccessory(for textField: UISearchTextField, isSearching: Bool) {
            if isSearching {
                if textField.leftView !== loadingIndicator {
                    textField.leftView = loadingIndicator
                    textField.leftViewMode = .always
                }
                loadingIndicator.startAnimating()
            } else {
                loadingIndicator.stopAnimating()
                if textField.leftView !== defaultLeftView {
                    textField.leftView = defaultLeftView
                    textField.leftViewMode = defaultLeftViewMode
                }
            }
        }

        @objc func textDidChange(_ sender: UITextField) {
            text = sender.text ?? ""
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            isFocused = true
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            isFocused = false
        }

        func textFieldShouldClear(_ textField: UITextField) -> Bool {
            text = ""
            return true
        }
    }
}
