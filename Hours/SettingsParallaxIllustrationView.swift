import SwiftUI

struct SettingsParallaxIllustrationView: View {
    @StateObject private var motionManager = ParallaxMotionManager()

    var body: some View {
        Image("settings_parallax_back")
            .resizable()
            .scaledToFit()
            .offset(
                x: motionManager.normalizedOffset.width * 6,
                y: motionManager.normalizedOffset.height * 6
            )
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
        Image(imageName)
            .resizable()
            .scaledToFit()
            .offset(
                x: motionManager.normalizedOffset.width * strength,
                y: motionManager.normalizedOffset.height * strength
            )
            .allowsHitTesting(false)
    }
}
