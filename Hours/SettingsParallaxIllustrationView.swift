import SwiftUI

struct SettingsParallaxIllustrationView: View {
    enum Variant: String {
        case light
        case dark
    }

    let variant: Variant
    @StateObject private var motionManager = ParallaxMotionManager()

    var body: some View {
        Image(themedAssetName(for: "settings_parallax_back"))
            .resizable()
            .scaledToFit()
            .offset(
                x: motionManager.normalizedOffset.width * 6,
                y: motionManager.normalizedOffset.height * 6
            )
            .id(imageIdentity(for: "settings_parallax_back"))
            .overlay {
                layer(named: "settings_parallax_mid", strength: 10)
                layer(named: "settings_parallax_front", strength: 16)
            }
            .frame(maxWidth: .infinity)
            .clipped()
            .accessibilityHidden(true)
            .onAppear {
                motionManager.start()
            }
            .onDisappear {
                motionManager.stop()
            }
    }

    private func layer(named imageName: String, strength: CGFloat) -> some View {
        Image(themedAssetName(for: imageName))
            .resizable()
            .scaledToFit()
            .offset(
                x: motionManager.normalizedOffset.width * strength,
                y: motionManager.normalizedOffset.height * strength
            )
            .id(imageIdentity(for: imageName))
            .allowsHitTesting(false)
    }

    private func themedAssetName(for baseName: String) -> String {
        "\(baseName)_\(variant.rawValue)"
    }

    private func imageIdentity(for imageName: String) -> String {
        themedAssetName(for: imageName)
    }
}
