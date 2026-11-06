import SwiftUI
import UIKit

struct ChangeCityNameSheetView: View {
    let city: City
    let onSave: (String?) -> Void

    private var originalName: String {
        city.canonicalCity.name
    }

    private var trimmedOriginalName: String {
        originalName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedSavedDisplayName: String {
        city.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var hasSavedCustomDisplayName: Bool {
        !(city.customDisplayName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    var body: some View {
        SingleTextEntrySheetView(
            title: "Change Name",
            initialText: city.displayName,
            placeholder: "",
            confirmButtonTitle: "Save",
            helperText: nil,
            showsOriginalButton: false,
            originalButtonTitle: "Original",
            originalReplacementText: originalName,
            showsConfirmButton: false,
            dynamicHelperText: { trimmedText in
                let shouldShowRestoreOriginalButton = hasSavedCustomDisplayName || trimmedText != trimmedOriginalName
                let isUsingOriginalNameValue = !shouldShowRestoreOriginalButton && trimmedText == trimmedOriginalName
                guard isUsingOriginalNameValue else { return nil }
                return "For example, the name of the person\nwho lives there"
            },
            dynamicShowsOriginalButton: { trimmedText in
                hasSavedCustomDisplayName || trimmedText != trimmedOriginalName
            },
            dynamicShowsConfirmButton: { trimmedText in
                trimmedText != trimmedSavedDisplayName
            },
            onConfirm: { trimmedText in
                onSave(normalizedCustomName(from: trimmedText))
                triggerNotificationHaptic(.success)
            },
            onDismiss: {}
        )
    }

    private func normalizedCustomName(from rawValue: String) -> String? {
        guard !rawValue.isEmpty else { return nil }
        guard rawValue != trimmedOriginalName else { return nil }
        return rawValue
    }
}

struct SingleTextEntrySheetView: View {
    let title: String
    let initialText: String
    let placeholder: String
    let confirmButtonTitle: String
    let helperText: String?
    let showsOriginalButton: Bool
    let originalButtonTitle: String
    let originalReplacementText: String
    let showsConfirmButton: Bool
    let dynamicHelperText: ((String) -> String?)?
    let dynamicShowsOriginalButton: ((String) -> Bool)?
    let dynamicShowsConfirmButton: ((String) -> Bool)?
    let onConfirm: (String) -> Void
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @State private var editableText: String
    @State private var isTextFieldFocused = false

    init(
        title: String,
        initialText: String,
        placeholder: String,
        confirmButtonTitle: String,
        helperText: String? = nil,
        showsOriginalButton: Bool = false,
        originalButtonTitle: String = "Original",
        originalReplacementText: String = "",
        showsConfirmButton: Bool = true,
        dynamicHelperText: ((String) -> String?)? = nil,
        dynamicShowsOriginalButton: ((String) -> Bool)? = nil,
        dynamicShowsConfirmButton: ((String) -> Bool)? = nil,
        onConfirm: @escaping (String) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.title = title
        self.initialText = initialText
        self.placeholder = placeholder
        self.confirmButtonTitle = confirmButtonTitle
        self.helperText = helperText
        self.showsOriginalButton = showsOriginalButton
        self.originalButtonTitle = originalButtonTitle
        self.originalReplacementText = originalReplacementText
        self.showsConfirmButton = showsConfirmButton
        self.dynamicHelperText = dynamicHelperText
        self.dynamicShowsOriginalButton = dynamicShowsOriginalButton
        self.dynamicShowsConfirmButton = dynamicShowsConfirmButton
        self.onConfirm = onConfirm
        self.onDismiss = onDismiss
        _editableText = State(initialValue: initialText)
    }

    private var trimmedEditableText: String {
        editableText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var resolvedHelperText: String? {
        dynamicHelperText?(trimmedEditableText) ?? helperText
    }

    private var resolvedShowsOriginalButton: Bool {
        dynamicShowsOriginalButton?(trimmedEditableText) ?? showsOriginalButton
    }

    private var resolvedShowsConfirmButton: Bool {
        dynamicShowsConfirmButton?(trimmedEditableText) ?? showsConfirmButton
    }

    private var isConfirmEnabled: Bool {
        !trimmedEditableText.isEmpty
    }

    private var bottomAccessoryHeight: CGFloat {
        68
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ZStack {
                    HStack(spacing: 0) {
                        Spacer(minLength: 0)

                        NativeCenteredNameTextField(
                            text: $editableText,
                            placeholder: placeholder,
                            isFocused: $isTextFieldFocused,
                            onSubmit: {
                                guard resolvedShowsConfirmButton, isConfirmEnabled else { return }
                                confirmAndDismiss()
                            }
                        )
                        .frame(maxWidth: 420)
                        .frame(height: 58)
                        .clipped()

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            .background(
                SheetStyle.appScreenBackground(for: theme)
                    .ignoresSafeArea()
            )
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) {
                    if resolvedShowsOriginalButton {
                        Button {
                            triggerNotificationHaptic(.warning)
                            editableText = originalReplacementText
                            DispatchQueue.main.async {
                                isTextFieldFocused = true
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 13, weight: .medium))

                                Text(originalButtonTitle)
                                    .font(.system(size: 16, weight: .regular))
                                    .tracking(-0.48)
                            }
                            .foregroundStyle(theme.textInverse)
                            .padding(.horizontal, 10)
                            .frame(height: 32)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(theme.textPrimary.opacity(0.88))
                            )
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                    } else if let resolvedHelperText {
                        Text(resolvedHelperText)
                            .font(.system(size: 14, weight: .regular))
                            .tracking(-0.42)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(theme.textSecondary)
                            .transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: bottomAccessoryHeight, alignment: .center)
                .animation(.easeInOut(duration: 0.16), value: resolvedShowsOriginalButton)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        onDismiss()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(theme.textPrimary)
                    }
                    .buttonStyle(.plain)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if resolvedShowsConfirmButton {
                        Button(confirmButtonTitle) {
                            confirmAndDismiss()
                        }
                        .font(.system(size: 17, weight: .medium))
                        .tracking(-0.41)
                        .foregroundStyle(theme.textPrimary)
                        .opacity(isConfirmEnabled ? 1 : 0.4)
                        .disabled(!isConfirmEnabled)
                        .padding(.top, -2)
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.async {
                    isTextFieldFocused = true
                }
            }
        }
    }

    private func confirmAndDismiss() {
        guard resolvedShowsConfirmButton, isConfirmEnabled else { return }
        onConfirm(trimmedEditableText)
        dismiss()
    }
}

private func triggerNotificationHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
    let fire = {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    if Thread.isMainThread {
        fire()
    } else {
        DispatchQueue.main.async(execute: fire)
    }
}

private struct NativeCenteredNameTextField: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    @Binding var isFocused: Bool
    let onSubmit: () -> Void
    @Environment(\.appTheme) private var theme

    private var textColor: UIColor {
        UIColor(theme.textPrimary)
    }

    private var placeholderColor: UIColor {
        UIColor(theme.textSecondary)
    }

    private var placeholderAttributes: [NSAttributedString.Key: Any] {
        [
            .font: UIFont.systemFont(ofSize: 40, weight: .semibold),
            .foregroundColor: placeholderColor,
            .kern: -0.96
        ]
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.delegate = context.coordinator
        textField.font = .systemFont(ofSize: 40, weight: .medium)
        textField.adjustsFontForContentSizeCategory = true
        textField.returnKeyType = .done
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .words
        textField.textAlignment = .center
        textField.textColor = textColor
        textField.adjustsFontSizeToFitWidth = true
        textField.minimumFontSize = 20
        textField.backgroundColor = .clear
        textField.borderStyle = .none
        textField.clearButtonMode = .never
        textField.tintColor = UIColor(theme.accent)
        textField.clipsToBounds = true
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.placeholder = placeholder
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: placeholderAttributes
        )
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textDidChange(_:)), for: .editingChanged)
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        let didProgrammaticallyChangeText = uiView.text != text
        if didProgrammaticallyChangeText {
            uiView.text = text
        }

        uiView.textColor = textColor
        uiView.tintColor = UIColor(theme.accent)

        if uiView.placeholder != placeholder {
            uiView.placeholder = placeholder
            uiView.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: placeholderAttributes
            )
        } else {
            uiView.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: placeholderAttributes
            )
        }

        if isFocused {
            if uiView.isFirstResponder {
                if didProgrammaticallyChangeText {
                    context.coordinator.moveCaretToEnd(in: uiView)
                }
                return
            }

            DispatchQueue.main.async {
                uiView.becomeFirstResponder()
                context.coordinator.moveCaretToEnd(in: uiView)
            }
        } else if uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, isFocused: $isFocused, onSubmit: onSubmit)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        @Binding private var text: String
        @Binding private var isFocused: Bool
        private let onSubmit: () -> Void

        init(text: Binding<String>, isFocused: Binding<Bool>, onSubmit: @escaping () -> Void) {
            _text = text
            _isFocused = isFocused
            self.onSubmit = onSubmit
        }

        @objc func textDidChange(_ sender: UITextField) {
            text = sender.text ?? ""
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            isFocused = true
            moveCaretToEnd(in: textField)
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            isFocused = false
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            onSubmit()
            return false
        }

        func moveCaretToEnd(in textField: UITextField) {
            DispatchQueue.main.async {
                let end = textField.endOfDocument
                textField.selectedTextRange = textField.textRange(from: end, to: end)
            }
        }
    }
}
