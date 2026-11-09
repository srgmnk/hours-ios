import Foundation
import CryptoKit

// Compile the real route model without bringing SwiftUI into these offline checks.
enum AppThemeVariant { case light, dark }
struct AppTheme { let variant: AppThemeVariant }

@main struct AttributionTests {
    static var checks = 0

    static func check(_ value: @autoclosure () -> Bool, _ label: String) {
        precondition(value(), label)
        checks += 1
    }

    static func digest(_ bytes: Data) -> String {
        SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
    }

    static func fixtureBundle(root: URL, resourceDirectory: URL, nested: Bool) throws -> Bundle {
        let path = root.appendingPathComponent(nested ? "Nested.bundle" : "Flat.bundle")
        let resources = nested ? path.appendingPathComponent("Features/Settings/Legal") : path
        try FileManager.default.createDirectory(at: resources, withIntermediateDirectories: true)
        let info = ["CFBundleIdentifier": "ai.srgmnk.hours.attribution-tests", "CFBundlePackageType": "BNDL"]
        try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
            .write(to: path.appendingPathComponent("Info.plist"))
        for name in ["CityDataAttribution.txt", "GeoNames-CC-BY-4.0.txt"] {
            try FileManager.default.copyItem(at: resourceDirectory.appendingPathComponent(name),
                                            to: resources.appendingPathComponent(name))
        }
        return Bundle(path: path.path)!
    }

    static func main() throws {
        let repository = URL(fileURLWithPath: CommandLine.arguments[1])
        let temporary = URL(fileURLWithPath: CommandLine.arguments[2])
        let resources = repository.appendingPathComponent("Hours/Features/Settings/Legal")
        for variant in [AppThemeVariant.light, .dark] {
            let theme = AppTheme(variant: variant)
            for (document, path) in [(LegalDocument.privacy, "/hours/privacy/"), (.terms, "/hours/terms/")] {
                let url = document.url(for: theme)!
                check(url.absoluteString == "https://sergy.xyz\(path)?theme=\(variant == .dark ? "dark" : "light")",
                      "Existing privacy and terms destinations are preserved")
                check(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems == [
                    URLQueryItem(name: "theme", value: variant == .dark ? "dark" : "light")
                ], "Existing legal theme routing is preserved")
            }
            check(LegalDocument.dataAttribution.url(for: theme) == nil,
                  "Data attribution uses the offline native destination")
        }
        check(LegalDocument.dataAttribution.id == "dataAttribution" &&
              LegalDocument.dataAttribution.title == "Data Attribution", "Dedicated attribution sheet identity")
        check(CityDataAttribution.sourceURL.absoluteString == "https://www.geonames.org/", "Official source link")
        check(CityDataAttribution.licenseURL.absoluteString == "https://creativecommons.org/licenses/by/4.0/", "CC BY 4.0 link")
        check(CityDataAttribution.modifications.contains("November 8, 2026"), "Snapshot and modification notice")
        check(CityDataAttribution.separateLicense.contains("do not restrict your rights"), "Data license is separate from app terms")

        let cityData = try Data(contentsOf: repository.appendingPathComponent("Hours/Resources/cities.json"))
        let catalogDigest = digest(cityData)
        for nested in [false, true] {
            let bundle = try fixtureBundle(root: temporary, resourceDirectory: resources, nested: nested)
            let notice = CityDataAttribution.sourceNotice(in: bundle)!
            check(notice.contains(catalogDigest), "Bundled notice identifies the actual shipped catalog")
            check(notice.contains("https://www.geonames.org/") &&
                  notice.contains("https://creativecommons.org/licenses/by/4.0/"), "Source and license remain readable offline")
            check(notice.contains("Selected, formatted and adapted") && notice.contains("2026-11-08"), "Changes and dated snapshot recorded")
            check(notice.contains("without warranty") && notice.contains("separately from the Hours app"), "Notices and independent data license retained")
            check(notice.contains("75703cd2ed918ce38bf78ab50c7d7a93cba7f077325feefbd1df95e0474c3f7e"), "Approved alias-source fingerprint retained")
            let legalCode = CityDataAttribution.licenseText(in: bundle)!
            check(digest(Data(legalCode.utf8)) == "9ba9550ad48438d0836ddab3da480b3b69ffa0aac7b7878b5a0039e7ab429411",
                  "Complete upstream license text remains unmodified")
        }
        print("PASS: \(checks) attribution route, preserved legal URLs, bundle-layout, notice and catalog/license fingerprint checks")
    }
}
