import SwiftUI

/// A passive icon: all three hands use the same instant supplied by the screen.
struct AnalogClockSwitcherIcon: View {
    let instant: Date
    let timeZone: TimeZone
    @Environment(\.appTheme) private var theme

    var body: some View {
        let angles = AnalogClockAngles(instant: instant, timeZone: timeZone)
        let handColor = theme.variant == .dark ? Color.white : Color(white: 17.0 / 255.0)
        Canvas { context, _ in
            context.fill(Path(ellipseIn: CGRect(x: 0, y: 0, width: 36, height: 36)),
                         with: .color(SheetStyle.appScreenBackground(for: theme)))
            // Figma's hands point to 1:30 and 10:30; rotate around its (18,18) pivot.
            func draw(_ path: Path, degrees: Double, color: Color) {
                var handContext = context
                handContext.translateBy(x: 18, y: 18)
                handContext.rotate(by: .degrees(degrees))
                handContext.translateBy(x: -18, y: -18)
                handContext.fill(path, with: .color(color))
            }
            draw(ClockSwitcherPaths.hour, degrees: angles.hour - 45, color: handColor)
            draw(ClockSwitcherPaths.minute, degrees: angles.minute + 45, color: handColor)
            draw(ClockSwitcherPaths.second, degrees: angles.second,
                 color: Color(red: 1, green: 64.0 / 255.0, blue: 0))
        }
        .frame(width: 36, height: 36)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Calendar conversion handles fractional offsets and DST at the selected instant.
struct AnalogClockAngles: Equatable {
    let hour: Double
    let minute: Double
    let second: Double

    init(instant: Date, timeZone: TimeZone) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let local = calendar.dateComponents([.hour, .minute, .second, .nanosecond], from: instant)
        let seconds = Double(local.second ?? 0) + Double(local.nanosecond ?? 0) / 1_000_000_000
        let minutes = Double(local.minute ?? 0) + seconds / 60
        hour = (Double((local.hour ?? 0) % 12) + minutes / 60) * 30
        minute = minutes * 6
        second = seconds * 6
    }
}

// Exact vector outlines from Figma 681:10993, in its 36 pt coordinate space.
// Layer order: Back, Hour, Minute, then "Secund" with its integrated 4 pt hub.
private enum ClockSwitcherPaths {
    static let hour = {
        var path = Path()
        path.move(to: CGPoint(x: 25.7763, y: 8.80867))
        path.addCurve(to: CGPoint(x: 27.1905, y: 8.80867), control1: CGPoint(x: 26.1668, y: 8.41815), control2: CGPoint(x: 26.8, y: 8.41815))
        path.addCurve(to: CGPoint(x: 27.1905, y: 10.2229), control1: CGPoint(x: 27.581, y: 9.1992), control2: CGPoint(x: 27.581, y: 9.83236))
        path.addLine(to: CGPoint(x: 21.7104, y: 15.703))
        path.addCurve(to: CGPoint(x: 21.3569, y: 15.703), control1: CGPoint(x: 21.6128, y: 15.8006), control2: CGPoint(x: 21.4545, y: 15.8006))
        path.addCurve(to: CGPoint(x: 21.0033, y: 15.703), control1: CGPoint(x: 21.2592, y: 15.6053), control2: CGPoint(x: 21.101, y: 15.6053))
        path.addLine(to: CGPoint(x: 18.3517, y: 18.3546))
        path.addCurve(to: CGPoint(x: 17.6446, y: 18.3546), control1: CGPoint(x: 18.1564, y: 18.5499), control2: CGPoint(x: 17.8398, y: 18.5499))
        path.addCurve(to: CGPoint(x: 17.6446, y: 17.6475), control1: CGPoint(x: 17.4493, y: 18.1594), control2: CGPoint(x: 17.4493, y: 17.8428))
        path.addLine(to: CGPoint(x: 20.2962, y: 14.9959))
        path.addCurve(to: CGPoint(x: 20.2962, y: 14.6423), control1: CGPoint(x: 20.3938, y: 14.8982), control2: CGPoint(x: 20.3938, y: 14.7399))
        path.addCurve(to: CGPoint(x: 20.2962, y: 14.2887), control1: CGPoint(x: 20.1986, y: 14.5447), control2: CGPoint(x: 20.1986, y: 14.3864))
        path.addLine(to: CGPoint(x: 25.7763, y: 8.80867))
        path.closeSubpath()
        return path
    }()

    static let minute = {
        var path = Path()
        path.move(to: CGPoint(x: 6.69149, y: 8.10156))
        path.addCurve(to: CGPoint(x: 6.69149, y: 6.68735), control1: CGPoint(x: 6.30096, y: 7.71104), control2: CGPoint(x: 6.30096, y: 7.07787))
        path.addCurve(to: CGPoint(x: 8.1057, y: 6.68735), control1: CGPoint(x: 7.08201, y: 6.29683), control2: CGPoint(x: 7.71518, y: 6.29683))
        path.addLine(to: CGPoint(x: 15.7071, y: 14.2888))
        path.addCurve(to: CGPoint(x: 15.7071, y: 14.6423), control1: CGPoint(x: 15.8047, y: 14.3864), control2: CGPoint(x: 15.8047, y: 14.5447))
        path.addCurve(to: CGPoint(x: 15.7071, y: 14.9959), control1: CGPoint(x: 15.6095, y: 14.7399), control2: CGPoint(x: 15.6095, y: 14.8982))
        path.addLine(to: CGPoint(x: 18.3587, y: 17.6475))
        path.addCurve(to: CGPoint(x: 18.3587, y: 18.3546), control1: CGPoint(x: 18.554, y: 17.8428), control2: CGPoint(x: 18.554, y: 18.1593))
        path.addCurve(to: CGPoint(x: 17.6516, y: 18.3546), control1: CGPoint(x: 18.1635, y: 18.5499), control2: CGPoint(x: 17.8469, y: 18.5499))
        path.addLine(to: CGPoint(x: 15, y: 15.703))
        path.addCurve(to: CGPoint(x: 14.6464, y: 15.703), control1: CGPoint(x: 14.9024, y: 15.6053), control2: CGPoint(x: 14.7441, y: 15.6053))
        path.addCurve(to: CGPoint(x: 14.2929, y: 15.703), control1: CGPoint(x: 14.5488, y: 15.8006), control2: CGPoint(x: 14.3905, y: 15.8006))
        path.addLine(to: CGPoint(x: 6.69149, y: 8.10156))
        path.closeSubpath()
        return path
    }()

    static let second = {
        var path = Path()
        path.move(to: CGPoint(x: 18, y: 2))
        path.addCurve(to: CGPoint(x: 18.5, y: 2.5), control1: CGPoint(x: 18.2761, y: 2.00004), control2: CGPoint(x: 18.5, y: 2.22389))
        path.addLine(to: CGPoint(x: 18.5, y: 14.5155))
        path.addCurve(to: CGPoint(x: 19.7128, y: 16.9679), control1: CGPoint(x: 18.5, y: 15.4278), control2: CGPoint(x: 19.2402, y: 16.1875))
        path.addCurve(to: CGPoint(x: 20, y: 18), control1: CGPoint(x: 19.8951, y: 17.269), control2: CGPoint(x: 20, y: 17.622))
        path.addCurve(to: CGPoint(x: 18, y: 20), control1: CGPoint(x: 20, y: 19.1046), control2: CGPoint(x: 19.1046, y: 20))
        path.addCurve(to: CGPoint(x: 16, y: 18), control1: CGPoint(x: 16.8954, y: 20), control2: CGPoint(x: 16, y: 19.1046))
        path.addCurve(to: CGPoint(x: 16.2872, y: 16.9679), control1: CGPoint(x: 16, y: 17.622), control2: CGPoint(x: 16.1049, y: 17.269))
        path.addCurve(to: CGPoint(x: 17.5, y: 14.5155), control1: CGPoint(x: 16.7598, y: 16.1875), control2: CGPoint(x: 17.5, y: 15.4278))
        path.addLine(to: CGPoint(x: 17.5, y: 2.5))
        path.addCurve(to: CGPoint(x: 18, y: 2), control1: CGPoint(x: 17.5, y: 2.22386), control2: CGPoint(x: 17.7239, y: 2))
        path.closeSubpath()
        return path
    }()
}
