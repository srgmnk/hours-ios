import SwiftUI

struct DeltaPillView: View {
    @Environment(\.appTheme) private var theme

    enum PillMode {
        case now
        case future
        case past
    }

    let mode: PillMode
    let deltaText: String
    let onTapReset: () -> Void

    private let pillShape = RoundedRectangle(cornerRadius: 100, style: .continuous)
    private var appearance: DialPillAppearance {
        switch mode {
        case .now:
            return theme.pillNow
        case .future:
            return theme.pillFuture
        case .past:
            return theme.pillPast
        }
    }

    var body: some View {
        pillContent
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(appearance.foregroundColor)
            .lineLimit(1)
            .lineSpacing(0)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(height: 30)
            .fixedSize(horizontal: true, vertical: false)
            .modifier(PillGlassEffectModifier(appearance: appearance, shape: pillShape))
            .contentShape(pillShape)
            .highPriorityGesture(TapGesture().onEnded {
                onTapReset()
            })
    }

    private var pillContent: some View {
        HStack(spacing: 2) {
            switch mode {
            case .now:
                Text("Now")
            case .future:
                Image(systemName: "plus.circle.fill")
                Text(deltaText)
                    .monospacedDigit()
            case .past:
                Image(systemName: "minus.circle.fill")
                Text(deltaText)
                    .monospacedDigit()
            }
        }
    }

    private var horizontalPadding: CGFloat {
        mode == .now ? 12 : 8
    }

    private var verticalPadding: CGFloat {
        mode == .now ? 8 : 4
    }
}

private struct PillGlassEffectModifier: ViewModifier {
    let appearance: DialPillAppearance
    let shape: RoundedRectangle

    @ViewBuilder
    func body(content: Content) -> some View {
        if let tint = appearance.glassTintColor {
            if appearance.usesInteractiveGlass {
                content
                    .glassEffect(.regular.tint(tint).interactive(), in: shape)
            } else {
                content
                    .glassEffect(.regular.tint(tint), in: shape)
            }
        } else if appearance.usesInteractiveGlass {
            content
                .glassEffect(.regular.interactive(), in: shape)
        } else {
            content
                .glassEffect(.regular, in: shape)
        }
    }
}
