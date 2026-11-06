import SwiftUI

struct SettingsParallaxIllustrationView: View {
    enum Variant: String {
        case light
        case dark
    }

    let variant: Variant

    var body: some View {
        LayeredParallaxIllustrationView(
            backImageName: themedAssetName(for: "settings_parallax_back"),
            middleImageName: themedAssetName(for: "settings_parallax_mid"),
            frontImageName: themedAssetName(for: "settings_parallax_front")
        )
    }

    private func themedAssetName(for baseName: String) -> String {
        "\(baseName)_\(variant.rawValue)"
    }
}
