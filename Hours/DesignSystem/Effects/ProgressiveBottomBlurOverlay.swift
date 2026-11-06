import SwiftUI

struct ProgressiveBottomBlurOverlay: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme

    let height: CGFloat

    private var isDarkMode: Bool {
        colorScheme == .dark
    }

    private var lightBlurMaskStops: [Gradient.Stop] {
        [
            .init(color: .black.opacity(1.0), location: 0.0),
            .init(color: .black.opacity(0.95), location: 0.2),
            .init(color: .black.opacity(0.65), location: 0.55),
            .init(color: .clear, location: 1.0)
        ]
    }

    private var darkBaseStops: [Gradient.Stop] {
        [
            .init(color: theme.screenBackground.opacity(1.0), location: 0.0),
            .init(color: theme.screenBackground.opacity(0.96), location: 0.22),
            .init(color: theme.screenBackground.opacity(0.78), location: 0.58),
            .init(color: .clear, location: 1.0)
        ]
    }

    private var darkDepthStops: [Gradient.Stop] {
        [
            .init(color: theme.screenBackground.opacity(0.60), location: 0.0),
            .init(color: theme.screenBackground.opacity(0.35), location: 0.18),
            .init(color: theme.screenBackground.opacity(0.13), location: 0.50),
            .init(color: .clear, location: 1.0)
        ]
    }

    private var lightDissolveStops: [Gradient.Stop] {
        [
            .init(color: Color.white.opacity(0.50), location: 0.0),
            .init(color: Color.white.opacity(0.30), location: 0.35),
            .init(color: Color.white.opacity(0.12), location: 0.7),
            .init(color: .clear, location: 1.0)
        ]
    }

    private var darkDissolveStops: [Gradient.Stop] {
        [
            .init(color: theme.screenBackground.opacity(0.42), location: 0.0),
            .init(color: theme.screenBackground.opacity(0.24), location: 0.36),
            .init(color: theme.screenBackground.opacity(0.10), location: 0.74),
            .init(color: .clear, location: 1.0)
        ]
    }

    private var lightOverlay: some View {
        ZStack {
            // Keep light mode on the existing material-based progressive blur recipe.
            Rectangle()
                .fill(.thickMaterial)
                .mask(
                    LinearGradient(
                        stops: lightBlurMaskStops,
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )

            LinearGradient(
                stops: lightDissolveStops,
                startPoint: .bottom,
                endPoint: .top
            )
        }
    }

    private var darkOverlay: some View {
        ZStack {
            // Dark mode intentionally avoids Material to prevent gray glass tinting.
            LinearGradient(
                stops: darkBaseStops,
                startPoint: .bottom,
                endPoint: .top
            )

            LinearGradient(
                stops: darkDepthStops,
                startPoint: .bottom,
                endPoint: .top
            )

            LinearGradient(
                stops: darkDissolveStops,
                startPoint: .bottom,
                endPoint: .top
            )
        }
    }

    var body: some View {
        Group {
            if isDarkMode {
                darkOverlay
            } else {
                lightOverlay
            }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .allowsHitTesting(false)
    }
}
