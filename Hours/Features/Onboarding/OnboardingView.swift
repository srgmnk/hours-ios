import SwiftUI
import UIKit

enum OnboardingStorageKey {
    static let hasCompleted = "hasCompletedOnboarding"
}

struct OnboardingView: View {
    @AppStorage(OnboardingStorageKey.hasCompleted) private var hasCompletedOnboarding = false
    @Environment(\.appTheme) private var theme
    @State private var currentStep: OnboardingStep = .step1
    @State private var duoHinge = DuoHingeState()

    var body: some View {
        Group {
            if #available(iOS 27.1, *), duoHinge.isConfirmed {
                DuoOnboardingContainer(hinge: duoHinge) { layout in
                    ZStack {
                        SheetStyle.appScreenBackground(for: theme)
                        DuoOnboardingStepView(step: currentStep, layout: layout)
                            .id(currentStep)
                            .transition(.opacity)
                        Button(action: advance) {
                            Text(currentStep.buttonTitle)
                                .font(.system(size: 16 * layout.scale, weight: .medium))
                                .tracking(-0.64 * layout.scale)
                                .foregroundStyle(theme.textPrimary)
                                .frame(width: layout.button.width, height: layout.button.height)
                                .modifier(GlassSurfaceModifier(shape: Capsule()))
                        }
                        .buttonStyle(.plain)
                        .position(x: layout.button.midX, y: layout.button.midY)
                    }
                    .frame(width: layout.bounds.width, height: layout.bounds.height)
                    .clipped()
                }
            } else {
                conventionalPresentation
            }
        }
        .background {
            DuoHingeObserver { status in duoHinge.receive(status) }
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    // Keep conventional geometry, typography and interaction exactly as before.
    private var conventionalPresentation: some View {
        GeometryReader { geo in
            let widthScale = geo.size.width / OnboardingLayout.canvasWidth
            let fullHeight = geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom
            let heightScale = (fullHeight - geo.safeAreaInsets.bottom) / OnboardingLayout.contentHeight
            let scale = min(widthScale, heightScale)
            let buttonBottom = scale < widthScale
                ? max(OnboardingLayout.buttonBottom * scale, geo.safeAreaInsets.bottom)
                : OnboardingLayout.buttonBottom * scale

            ZStack {
                SheetStyle.appScreenBackground(for: theme)
                    .ignoresSafeArea()

                OnboardingStepView(step: currentStep, scale: scale)
                    .frame(width: OnboardingLayout.canvasWidth * scale)
                    .id(currentStep)
                    .transition(.opacity)

                VStack {
                    Spacer()

                    Button(action: advance) {
                        Text(currentStep.buttonTitle)
                            .font(.system(size: 16 * scale, weight: .medium))
                            .tracking(-0.64 * scale)
                            .foregroundStyle(theme.textPrimary)
                            .frame(width: OnboardingLayout.buttonWidth * scale, height: OnboardingLayout.buttonHeight * scale)
                            .modifier(GlassSurfaceModifier(shape: Capsule()))
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, buttonBottom)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
        }
    }

    private func advance() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        withAnimation(.easeInOut(duration: 0.2)) {
            if currentStep == .step1 {
                currentStep = .step2
            } else {
                hasCompletedOnboarding = true
            }
        }
    }
}

private struct DuoOnboardingStepView: View {
    let step: OnboardingStep
    let layout: DuoOnboardingLayout
    @Environment(\.appTheme) private var theme

    var body: some View {
        ZStack {
            LayeredParallaxIllustrationView(
                backImageName: step.backImageName,
                middleImageName: step.middleImageName,
                frontImageName: step.frontImageName
            )
            .frame(width: layout.artwork.width, height: layout.artwork.height)
            .position(x: layout.artwork.midX, y: layout.artwork.midY)
            .mask(alignment: .topLeading) {
                Rectangle()
                    .frame(width: layout.artworkClip.width, height: layout.artworkClip.height)
                    .offset(x: layout.artworkClip.minX, y: layout.artworkClip.minY)
            }

            Image("HoursLogo")
                .resizable()
                .scaledToFit()
                .frame(width: layout.logo.width, height: layout.logo.height)
                .position(x: layout.logo.midX, y: layout.logo.midY)
                .accessibilityHidden(true)

            headline(step.headline1, width: step.headline1Width)
                .position(x: layout.headline1Center.x, y: layout.headline1Center.y)
            headline(step.headline2, width: step.headline2Width)
                .position(x: layout.headline2Center.x, y: layout.headline2Center.y)
        }
        .frame(width: layout.bounds.width, height: layout.bounds.height)
        .compositingGroup()
    }

    private func headline(_ text: String, width: CGFloat) -> some View {
        // Explicit existing copy breaks, with Figma's 30pt baseline spacing.
        VStack(spacing: 0) {
            ForEach(Array(text.split(separator: "\n").enumerated()), id: \.offset) { _, line in
                Text(String(line))
                    .font(.system(size: 32 * layout.scale, weight: .medium))
                    .tracking(-0.96 * layout.scale)
                    .frame(height: 30 * layout.scale)
            }
        }
        .foregroundStyle(theme.variant == .dark ? theme.textPrimary.opacity(0.9) : Color.black.opacity(0.8))
        .multilineTextAlignment(.center)
        .frame(width: width * layout.scale)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }
}

private struct OnboardingStepView: View {
    let step: OnboardingStep
    let scale: CGFloat

    @Environment(\.appTheme) private var theme

    var body: some View {
        ZStack {
            Image("HoursLogo")
                .resizable()
                .scaledToFit()
                .frame(
                    width: OnboardingLayout.logoWidth * scale,
                    height: OnboardingLayout.logoHeight * scale
                )
                .position(
                    x: OnboardingLayout.canvasWidth * scale / 2,
                    y: (OnboardingLayout.logoTop + (OnboardingLayout.logoHeight / 2)) * scale
                )
                .accessibilityHidden(true)

            VStack(spacing: OnboardingLayout.headlineSpacing * scale) {
                headline(step.headline1, width: step.headline1Width)
                headline(step.headline2, width: step.headline2Width)
            }
            .position(
                x: OnboardingLayout.canvasWidth * scale / 2,
                y: ((OnboardingLayout.headline1Top + OnboardingLayout.headlineBlockHeight / 2) + (OnboardingLayout.headline2Top + OnboardingLayout.headlineBlockHeight / 2)) * scale / 2
            )

            LayeredParallaxIllustrationView(
                backImageName: step.backImageName,
                middleImageName: step.middleImageName,
                frontImageName: step.frontImageName
            )
            .frame(
                width: OnboardingLayout.artworkWidth * scale,
                height: OnboardingLayout.artworkHeight * scale
            )
            .position(
                x: OnboardingLayout.canvasWidth * scale / 2,
                y: (OnboardingLayout.artworkTop + (OnboardingLayout.artworkHeight / 2)) * scale
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .compositingGroup()
    }

    private func headline(_ text: String, width: CGFloat) -> some View {
        Text(text)
            .font(.system(size: 32 * scale, weight: .medium))
            .tracking(-0.96 * scale)
            .foregroundStyle(theme.textPrimary.opacity(theme.variant == .dark ? 0.9 : 0.8))
            .multilineTextAlignment(.center)
            .lineSpacing(-1 * scale)
            .frame(width: width * scale)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private enum OnboardingStep: Int, CaseIterable {
    case step1
    case step2

    var headline1: String {
        switch self {
        case .step1:
            return "Find and add a city\nor time zone"
        case .step2:
            return "Spin the dial to move\nthrough time"
        }
    }

    var headline2: String {
        switch self {
        case .step1:
            return "Rename them\nif you want"
        case .step2:
            return "Add a widget to your\nlock screen"
        }
    }

    var headline1Width: CGFloat {
        313
    }

    var headline2Width: CGFloat {
        switch self {
        case .step1:
            return 190
        case .step2:
            return 330
        }
    }

    var backImageName: String {
        switch self {
        case .step1:
            return "step-1-back"
        case .step2:
            return "step-2-back"
        }
    }

    var middleImageName: String {
        switch self {
        case .step1:
            return "step-1-middle"
        case .step2:
            return "step-2-middle"
        }
    }

    var frontImageName: String {
        switch self {
        case .step1:
            return "step-1-front"
        case .step2:
            return "step-2-front"
        }
    }

    var buttonTitle: String {
        switch self {
        case .step1:
            return "Next up"
        case .step2:
            return "Jump up"
        }
    }
}

private enum OnboardingLayout {
    static let canvasWidth: CGFloat = 393
    static let logoTop: CGFloat = 120
    static let logoWidth: CGFloat = 49
    static let logoHeight: CGFloat = 15
    static let headline1Top: CGFloat = 200
    static let headline2Top: CGFloat = 275
    static let headlineBlockHeight: CGFloat = 60
    static let headlineSpacing: CGFloat = 32
    static let artworkTop: CGFloat = 286
    static let artworkWidth: CGFloat = 593
    static let artworkHeight: CGFloat = 511
    static let contentHeight: CGFloat = artworkTop + artworkHeight
    static let buttonWidth: CGFloat = 345
    static let buttonHeight: CGFloat = 64
    static let buttonBottom: CGFloat = 24
}
