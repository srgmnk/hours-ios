import SwiftUI

struct LegalDocumentSheet: View {
    let document: LegalDocument

    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme

    var body: some View {
        NavigationStack {
            ZStack {
                SheetStyle.appScreenBackground(for: theme)
                    .ignoresSafeArea()

                if document == .dataAttribution {
                    CityDataAttributionView()
                } else if let url = document.url(for: theme) {
                    LegalWebView(url: url)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.clear)
                }
            }
            .navigationTitle(document.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    closeButton
                }
            }
        }
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .medium))
        }
        .buttonStyle(.plain)
    }
}
