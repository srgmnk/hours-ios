import SwiftUI
import UIKit

enum OnboardingStorageKey {
    static let hasCompleted = "hasCompletedOnboarding"
}

struct OnboardingView: View {
    @AppStorage(OnboardingStorageKey.hasCompleted) private var hasCompletedOnboarding = false
    @Environment(\.appTheme) private var theme
    @State private var currentStep: OnboardingStep = .step1

    var body: some View {
        GeometryReader { geo in
            let scale = geo.size.width / OnboardingLayout.canvasWidth

            ZStack {
                SheetStyle.appScreenBackground(for: theme)
                    .ignoresSafeArea()

                OnboardingStepView(step: currentStep, scale: scale)
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
                    .padding(.bottom, OnboardingLayout.buttonBottom * scale)
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
    static let buttonWidth: CGFloat = 345
    static let buttonHeight: CGFloat = 64
    static let buttonBottom: CGFloat = 24
}
