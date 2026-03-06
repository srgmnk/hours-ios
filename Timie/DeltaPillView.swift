import SwiftUI

struct DeltaPillView: View {
    enum PillMode {
        case now
        case future
        case past
    }

    let mode: PillMode
    let deltaText: String
    let onDoubleTapReset: () -> Void

    private let accentOrange = Color(red: 0xE8 / 255, green: 0x53 / 255, blue: 0x34 / 255)
    private let labelBlack = Color(red: 0x22 / 255, green: 0x22 / 255, blue: 0x22 / 255)
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
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 100, style: .continuous)
                            .fill(Color.white.opacity(0.01))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 100, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.6)
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
                .strokeBorder(Color.white.opacity(0.16), lineWidth: 0.6)
        }
        .overlay(alignment: .top) {
            pillShape
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
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
            return .black.opacity(0.3)
        case .past, .future:
            return .white
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
            return Color.black.opacity(0.2)
        case .past:
            return labelBlack
        case .future:
            return accentOrange
        }
    }
}
