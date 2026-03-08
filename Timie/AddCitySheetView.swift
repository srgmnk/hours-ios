import SwiftUI
import UIKit

struct AddCitySheetView: View {
    let existingTimeZoneIDs: Set<String>
    let onSelect: (CitySearchItem) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var results: [CitySearchItem] = []
    @State private var searchTask: Task<Void, Never>?
    @State private var isSearchFieldFocused = false

    private var isShowingEmptySearchState: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && results.isEmpty
    }

    var body: some View {
        let referenceDate = Date()

        NavigationStack {
            List {
                ForEach(Array(results.enumerated()), id: \.element.id) { index, item in
                    Button {
                        searchTask?.cancel()
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        dismiss()
                        onSelect(item)
                    } label: {
                        HStack(alignment: .center, spacing: 12) {
                            Text("\(item.city), \(item.country)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            Spacer(minLength: 8)

                            Text(utcOffsetText(for: item.timeZoneIdentifier, referenceDate: referenceDate))
                                .font(.system(size: 14, weight: .regular))
                                .foregroundStyle(.primary.opacity(0.3))
                                .monospacedDigit()
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 22)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(rowBackground(for: index, total: results.count))
                        .padding(.bottom, index == results.count - 1 ? 0 : 2)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .padding(.horizontal, 8)
            .navigationTitle("Add City")
            .navigationBarTitleDisplayMode(.inline)
            .overlay {
                if isShowingEmptySearchState {
                    ContentUnavailableView.search(text: query)
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomSearchArea
            }
        }
        .onAppear {
            performSearch(for: query)
            DispatchQueue.main.async {
                isSearchFieldFocused = true
            }
        }
        .onChange(of: query) { _, newQuery in
            performSearch(for: newQuery)
        }
        .onDisappear {
            searchTask?.cancel()
            isSearchFieldFocused = false
        }
    }

    private var bottomSearchArea: some View {
        GlassEffectContainer(spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                NativeBottomSearchTextField(
                    text: $query,
                    isFocused: $isSearchFieldFocused,
                    placeholder: "Search"
                )
                .frame(height: 52)
                .glassEffect(.regular, in: Capsule())

                if isSearchFieldFocused {
                    Button {
                        searchTask?.cancel()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundStyle(.primary)
                            .frame(width: 52, height: 52)
                            .glassEffect(.regular, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .animation(.easeInOut(duration: 0.16), value: isSearchFieldFocused)
    }

    private func performSearch(for query: String) {
        searchTask?.cancel()

        let local = CitySearchProvider.shared.localResults(
            matching: query,
            excluding: existingTimeZoneIDs
        )
        results = local

        guard CitySearchProvider.shared.shouldFetchFallback(for: query, localResultCount: local.count) else {
            return
        }

        searchTask = Task {
            let merged = await CitySearchProvider.shared.fallbackMergedResults(
                matching: query,
                localResults: local,
                excluding: existingTimeZoneIDs
            )

            guard !Task.isCancelled else { return }
            guard self.query == query else { return }

            await MainActor.run {
                results = merged
            }
        }
    }

    @ViewBuilder
    private func rowBackground(for index: Int, total: Int) -> some View {
        let backgroundColor = Color(red: 247.0 / 255.0, green: 247.0 / 255.0, blue: 247.0 / 255.0)

        if total <= 1 {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(backgroundColor)
        } else if index == 0 {
            UnevenRoundedRectangle(
                cornerRadii: .init(topLeading: 24, bottomLeading: 0, bottomTrailing: 0, topTrailing: 24),
                style: .continuous
            )
            .fill(backgroundColor)
        } else if index == total - 1 {
            UnevenRoundedRectangle(
                cornerRadii: .init(topLeading: 0, bottomLeading: 24, bottomTrailing: 24, topTrailing: 0),
                style: .continuous
            )
            .fill(backgroundColor)
        } else {
            Rectangle()
                .fill(backgroundColor)
        }
    }

    private func utcOffsetText(for timeZoneIdentifier: String, referenceDate: Date) -> String {
        guard let timeZone = TimeZone(identifier: timeZoneIdentifier) else {
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
}

private struct NativeBottomSearchTextField: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    let placeholder: String

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
        return textField
    }

    func updateUIView(_ uiView: UISearchTextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        if uiView.placeholder != placeholder {
            uiView.placeholder = placeholder
        }

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

        init(text: Binding<String>, isFocused: Binding<Bool>) {
            _text = text
            _isFocused = isFocused
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
