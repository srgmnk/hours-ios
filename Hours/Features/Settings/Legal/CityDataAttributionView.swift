import SwiftUI

struct CityDataAttributionView: View {
    @Environment(\.appTheme) private var theme

    private let sourceNotice = CityDataAttribution.sourceNotice()
    private let licenseText = CityDataAttribution.licenseText()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(CityDataAttribution.credit)
                    .font(.headline)
                Text(CityDataAttribution.modifications)
                Text(CityDataAttribution.separateLicense)

                VStack(alignment: .leading, spacing: 12) {
                    Link("GeoNames", destination: CityDataAttribution.sourceURL)
                    Link("CC BY 4.0 license", destination: CityDataAttribution.licenseURL)
                    Link("Original city data downloads", destination: CityDataAttribution.downloadURL)
                }

                Text(CityDataAttribution.disclaimer)

                if let licenseText {
                    DisclosureGroup("License text") {
                        Text(licenseText)
                            .font(.footnote)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 12)
                    }
                }

                if let sourceNotice {
                    DisclosureGroup("Data notice and source details") {
                        Text(sourceNotice)
                            .font(.footnote.monospaced())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 12)
                    }
                }
            }
            .foregroundStyle(theme.textPrimary)
            .tint(theme.accent)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .accessibilityIdentifier("legal.dataAttribution")
    }
}
