import SwiftUI

/// Presentation only: the existing OnboardingView owns progress and completion.
/// Figma 743:17047, 743:17866, 743:18670 and 743:19705 share native-size artwork.
struct DuoOnboardingLayout: Equatable {
    enum Arrangement: Equatable { case outer, compact, landscape, portrait }

    let arrangement: Arrangement
    let bounds: CGRect
    let artwork: CGRect
    let artworkClip: CGRect
    let logo: CGRect
    let headline1Center: CGPoint
    let headline2Center: CGPoint
    let button: CGRect
    let scale: CGFloat

    static func resolve(_ input: DuoLayoutConfiguration.Input) -> Self? {
        // Window width alone must never opt a conventional iPhone into Duo.
        guard input.hinge.isConfirmed, input.bounds.width > 0, input.bounds.height > 0,
              input.bounds.width.isFinite, input.bounds.height.isFinite else { return nil }
        let bounds = input.bounds
        let safe = input.safeContent.intersection(bounds)
        guard !safe.isNull, !safe.isEmpty else { return nil }
        // Use measured window geometry, not hinge angle, for equivalent postures.
        // The portrait display has top chrome; a Split View window has side chrome.
        let portrait = abs(bounds.width - 669) < 1 && abs(bounds.height - 951) < 1 &&
            input.railOnRight == nil && safe.minY > bounds.minY &&
            abs(safe.width - bounds.width) < 1
        let landscape = bounds.width >= 740 && bounds.width > bounds.height
        let outer = abs(bounds.width - 466) < 1 && abs(bounds.height - 678) < 1
        let arrangement: Arrangement = portrait ? .portrait : (landscape ? .landscape :
            (outer ? .outer : .compact))

        // A leading split pane has no system status column. Do not reserve the
        // main screen's control rail here: onboarding has no controls in it.
        let content = CGRect(x: safe.minX, y: bounds.minY, width: safe.width, height: bounds.height)
        let scale = min(1, content.width / 378, bounds.height / (portrait ? 951 : 669))
        let artworkSize = CGSize(width: 589.5 * scale, height: 507.5 * scale)
        let bottom = max(24 * scale, bounds.maxY - safe.maxY)
        let buttonHeight = 64 * scale
        let buttonY = bounds.maxY - bottom - buttonHeight
        var artworkCenter: CGPoint
        var artworkClip = bounds
        var logoOrigin: CGPoint
        var headline1: CGPoint
        var headline2: CGPoint
        var button: CGRect

        if portrait {
            // Top 476pt region: centered artwork with 80pt top padding. Bottom
            // 475pt region: 104pt side margins, 20pt top, then 8pt inner padding.
            let topHeight = bounds.height - 475
            artworkCenter = CGPoint(x: bounds.midX, y: bounds.minY + (topHeight + 80) / 2)
            artworkClip = CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: topHeight)
            logoOrigin = CGPoint(x: bounds.midX - 32.5, y: bounds.minY + 34)
            let textTop = bounds.minY + topHeight + 28
            let textCenter = textTop + (buttonY - textTop - 80) / 2
            headline1 = CGPoint(x: bounds.midX, y: textCenter - 50)
            headline2 = CGPoint(x: bounds.midX, y: textCenter + 50)
            button = CGRect(x: bounds.minX + 112, y: buttonY, width: bounds.width - 224, height: buttonHeight)
        } else if landscape {
            // Figma's left pane flexes; the text pane is 391pt and the status
            // column 80pt. Native safe-area measurements take precedence.
            let textWidth = min(391 * scale, content.width / 2)
            let textX = content.maxX - textWidth
            artworkCenter = CGPoint(x: (bounds.minX + textX) / 2 - 0.25 * scale,
                                    y: bounds.midY + 0.25 * scale)
            artworkClip = CGRect(x: bounds.minX, y: bounds.minY, width: textX - bounds.minX, height: bounds.height)
            let textCenterX = textX + textWidth / 2
            logoOrigin = CGPoint(x: textCenterX - 21.0869140625 * scale, y: bounds.minY + 25 * scale)
            // Space-between distribution of 56pt header, 160pt text, 64pt button.
            let textCenterY = (bounds.minY + 64 * scale + buttonY) / 2
            headline1 = CGPoint(x: textCenterX, y: textCenterY - 50 * scale)
            headline2 = CGPoint(x: textCenterX, y: textCenterY + 50 * scale)
            button = CGRect(x: textX + 8 * scale, y: buttonY,
                            width: textWidth - 16 * scale, height: buttonHeight)
        } else {
            let centerX = content.midX
            artworkCenter = CGPoint(x: centerX - 0.25 * scale,
                                    y: bounds.minY + (159 + 507.5 / 2) * scale)
            logoOrigin = CGPoint(x: centerX - (arrangement == .outer ? 23.0869140625 : 21.0869140625) * scale,
                                 y: bounds.minY + 25 * scale)
            headline1 = CGPoint(x: centerX + (arrangement == .outer ? 3.5 : -0.5) * scale,
                                y: bounds.minY + 129 * scale)
            headline2 = CGPoint(x: centerX + (arrangement == .outer ? 2 : 0) * scale,
                                y: bounds.minY + 213 * scale)
            let width = min(338 * scale, content.width - 48 * scale)
            button = CGRect(x: centerX - width / 2, y: buttonY, width: width, height: buttonHeight)
        }
        let artwork = CGRect(x: artworkCenter.x - artworkSize.width / 2,
                             y: artworkCenter.y - artworkSize.height / 2,
                             width: artworkSize.width, height: artworkSize.height)
        // A division is a transparent touch margin, not missing display space.
        // Moving the button for that margin would change equivalent postures.
        // Only an actual occlusion can affect its painted placement.
        for region in input.occlusions where button.intersects(region) {
            button.origin.y = min(button.minY, region.minY - button.height)
        }
        return Self(arrangement: arrangement, bounds: bounds, artwork: artwork, artworkClip: artworkClip,
                    logo: CGRect(origin: logoOrigin, size: CGSize(width: 48.4267578125 * scale, height: 14.853515625 * scale)),
                    headline1Center: headline1, headline2Center: headline2, button: button, scale: scale)
    }
}

/// Same measurement boundary as DuoLayoutContainer, without the main screen's
/// map/list/control allocations. No layout identity or animation depends on posture.
@available(iOS 27.1, *)
struct DuoOnboardingContainer<Content: View>: View {
    @Environment(\.toolbarVerticalEdge) private var toolbarEdge
    @Environment(\.layoutDirection) private var direction
    let hinge: DuoHingeState
    @ViewBuilder var content: (DuoOnboardingLayout) -> Content
    @State private var previous: DuoOnboardingLayout?

    var body: some View {
        GeometryReader { safe in
            GeometryReader { geometry in
                let origin = geometry.frame(in: .global).origin
                let safeFrame = safe.frame(in: .global).offsetBy(dx: -origin.x, dy: -origin.y)
                let right = toolbarEdge.map { direction == .leftToRight ? $0 == .trailing : $0 == .leading }
                let layout = DuoOnboardingLayout.resolve(.init(
                    hinge: hinge, bounds: CGRect(origin: .zero, size: geometry.size),
                    safeContent: safeFrame, railOnRight: right,
                    occlusions: geometry.reservedRegions(kind: .occlusion, layoutDirectionBehavior: .fixed).map(\.frame),
                    divisions: geometry.reservedRegions(kind: .division, layoutDirectionBehavior: .fixed).map(\.frame)
                ))
                if let resolved = layout ?? previous {
                    content(resolved)
                        .onChange(of: layout, initial: true) { _, value in
                            if let value, previous != value { previous = value }
                        }
                }
            }
            .ignoresSafeArea()
        }
    }
}
