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
    let onDoubleTapReset: () -> Void

    private let pillShape = RoundedRectangle(cornerRadius: 100, style: .continuous)

    var body: some View {
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
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(textColor)
        .lineLimit(1)
        .lineSpacing(0)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .frame(height: 30)
        .fixedSize(horizontal: true, vertical: false)
        .background {
            if mode == .now {
                RoundedRectangle(cornerRadius: 100, style: .continuous)
                    .fill(backgroundColor)
                    .overlay {
                        RoundedRectangle(cornerRadius: 100, style: .continuous)
                            .fill(textColor.opacity(0.03))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 100, style: .continuous)
                            .strokeBorder(textColor.opacity(0.05), lineWidth: 0.6)
                    }
            } else {
                RoundedRectangle(cornerRadius: 100, style: .continuous)
                    .fill(backgroundColor)
            }
        }
        .overlay {
            pillShape
                .fill(Color.white.opacity(0.05))
        }
        .overlay {
            pillShape
                .strokeBorder(Color.white.opacity(0.05), lineWidth: 0.6)
        }
        .overlay(alignment: .top) {
            pillShape
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                .mask(
                    LinearGradient(
                        colors: [.white, .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .contentShape(pillShape)
        .highPriorityGesture(TapGesture(count: 2).onEnded {
            onDoubleTapReset()
        })
    }
    
    private var textColor: Color {
        switch mode {
        case .now:
            return theme.pillNowForeground
        case .past:
            return theme.pillPastForeground
        case .future:
            return theme.pillFutureForeground
        }
    }
    
    private var horizontalPadding: CGFloat {
        mode == .now ? 12 : 8
    }

    private var verticalPadding: CGFloat {
        mode == .now ? 8 : 4
    }

    private var backgroundColor: Color {
        switch mode {
        case .now:
            return theme.pillNowBackground
        case .past:
            return theme.pillPastBackground
        case .future:
            return theme.pillFutureBackground
        }
    }
}
