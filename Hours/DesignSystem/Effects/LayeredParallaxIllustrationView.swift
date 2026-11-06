import SwiftUI

struct LayeredParallaxIllustrationView: View {
    let backImageName: String
    let middleImageName: String
    let frontImageName: String
    let backStrength: CGFloat
    let middleStrength: CGFloat
    let frontStrength: CGFloat

    @StateObject private var motionManager = ParallaxMotionManager()

    init(
        backImageName: String,
        middleImageName: String,
        frontImageName: String,
        backStrength: CGFloat = 6,
        middleStrength: CGFloat = 10,
        frontStrength: CGFloat = 16
    ) {
        self.backImageName = backImageName
        self.middleImageName = middleImageName
        self.frontImageName = frontImageName
        self.backStrength = backStrength
        self.middleStrength = middleStrength
        self.frontStrength = frontStrength
    }

    var body: some View {
        Image(backImageName)
            .resizable()
            .scaledToFit()
            .offset(
                x: motionManager.normalizedOffset.width * backStrength,
                y: motionManager.normalizedOffset.height * backStrength
            )
            .id(backImageName)
            .overlay {
                layer(named: middleImageName, strength: middleStrength)
                layer(named: frontImageName, strength: frontStrength)
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
            .id(imageName)
            .allowsHitTesting(false)
    }
}
