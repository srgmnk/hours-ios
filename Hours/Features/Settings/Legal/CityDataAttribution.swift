import Foundation

enum CityDataAttribution {
    static let sourceURL = URL(string: "https://www.geonames.org/")!
    static let downloadURL = URL(string: "https://download.geonames.org/export/dump/")!
    static let licenseURL = URL(string: "https://creativecommons.org/licenses/by/4.0/")!
    static let legalCodeURL = URL(string: "https://creativecommons.org/licenses/by/4.0/legalcode.en")!

    static let credit = "City data © GeoNames, licensed under Creative Commons Attribution 4.0 International (CC BY 4.0)."
    static let modifications = "Selected, formatted and adapted by Hours from the GeoNames snapshot downloaded on November 8, 2026. The catalog includes policy-based name and alias choices and documented editorial overrides. Existing Hours entries and approved coordinate exceptions were retained."
    static let separateLicense = "The city data remains available under CC BY 4.0. The Hours app is licensed separately; its Terms of Use do not restrict your rights under the city-data license. GeoNames does not endorse Hours."
    static let disclaimer = "GeoNames provides the data “as is,” without warranties of accuracy, timeliness or completeness."

    static func sourceNotice(in bundle: Bundle = .main) -> String? {
        bundledText(named: "CityDataAttribution", in: bundle)
    }

    static func licenseText(in bundle: Bundle = .main) -> String? {
        bundledText(named: "GeoNames-CC-BY-4.0", in: bundle)
    }

    private static func bundledText(named name: String, in bundle: Bundle) -> String? {
        let url = bundle.url(forResource: name, withExtension: "txt")
            ?? bundle.url(forResource: name, withExtension: "txt", subdirectory: "Features/Settings/Legal")
        guard let url else { return nil }
        return try? String(contentsOf: url, encoding: .utf8)
    }
}
