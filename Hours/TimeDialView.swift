import SwiftUI

struct TimeDialView: View {
    @Environment(\.appTheme) private var theme
    private static let tickCount = 288
    private static let tenMinuteTickInterval = 2
    private static let hourTickInterval = 12
    private static let minutesPerStep = 5

    let diameter: CGFloat
    let rotationDegrees: Double
    let stepIndex: Int // relStep: +future, -past
    let resetSignal: Int
    let maxInteractiveGlobalY: CGFloat
    let onDragBegan: () -> Void
    let onDragChanged: (Double) -> Void
    let onDragEnded: (Double, Double) -> Void

    @State private var dragStartAngle: Double?
    @State private var startRotationDegrees = 0.0

    var body: some View {
        let defaultTickColor = theme.textSecondary
        let offsetStepsSigned = stepIndex
        let offsetMinutes = offsetStepsSigned * Self.minutesPerStep
        let futureFillColor = theme.accent
        let pastFillColor = theme.textPrimary
        let fillColor = offsetStepsSigned > 0 ? futureFillColor : pastFillColor
        let centerTickIndex = Self.activeCenterTickIndex(rotationDegrees: rotationDegrees)
        let filledSet = Self.filledTickIndices(
            centerTickIndex: centerTickIndex,
            offsetStepsSigned: offsetStepsSigned
        )

        GeometryReader { geometry in
            ZStack {
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let outerRadius = (diameter / 2) - 16
                    let tenMinuteLength: CGFloat = 16
                    let hourLength: CGFloat = 24
                    let fiveMinuteLength: CGFloat = tenMinuteLength / 2
                    let minorWidth: CGFloat = 1
                    let majorWidth: CGFloat = 1

                    let degreesPerTick = 360.0 / Double(Self.tickCount)

                    // Layer 1: base ticks in gray.
                    for tick in 0..<Self.tickCount {
                        let baseLineWidth: CGFloat = (tick == centerTickIndex) ? 1.5 : 1
                        let tickPath = Self.tickPath(
                            tick: tick,
                            center: center,
                            outerRadius: outerRadius,
                            fiveMinuteLength: fiveMinuteLength,
                            tenMinuteLength: tenMinuteLength,
                            hourLength: hourLength,
                            minorWidth: minorWidth,
                            majorWidth: majorWidth,
                            lineWidth: baseLineWidth,
                            degreesPerTick: degreesPerTick,
                            rotationDegrees: rotationDegrees
                        )
                        context.fill(tickPath, with: .color(defaultTickColor))
                    }

                    // Layer 2: filled ticks overpainted with sign-based color.
                    if offsetMinutes != 0 {
                        for tick in 0..<Self.tickCount {
                            guard filledSet.contains(tick) else { continue }
                            let activeLineWidth: CGFloat = (tick == centerTickIndex || tick.isMultiple(of: Self.hourTickInterval)) ? 1.5 : 1
                            let tickPath = Self.tickPath(
                                tick: tick,
                                center: center,
                                outerRadius: outerRadius,
                                fiveMinuteLength: fiveMinuteLength,
                                tenMinuteLength: tenMinuteLength,
                                hourLength: hourLength,
                                minorWidth: minorWidth,
                                majorWidth: majorWidth,
                                lineWidth: activeLineWidth,
                                degreesPerTick: degreesPerTick,
                                rotationDegrees: rotationDegrees
                            )
                            context.fill(tickPath, with: .color(fillColor))
                        }
                    }
                }
                .frame(width: diameter, height: diameter)
            }
            .frame(width: diameter, height: diameter)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let frame = geometry.frame(in: .global)
                        guard !Self.isInBottomDeadZone(value.startLocation, frame: frame, maxInteractiveGlobalY: maxInteractiveGlobalY) else {
                            return
                        }

                        onDragBegan()
                        let center = CGPoint(x: diameter / 2, y: diameter / 2)
                        let clampedLocation = Self.clampedPoint(
                            value.location,
                            frame: frame,
                            maxInteractiveGlobalY: maxInteractiveGlobalY
                        )
                        let angle = Self.angleDegrees(point: clampedLocation, center: center)

                        if dragStartAngle == nil {
                            dragStartAngle = angle
                            startRotationDegrees = rotationDegrees
                        }

                        guard let dragStartAngle else { return }
                        let diff = Self.normalizedDeltaDegrees(from: dragStartAngle, to: angle)
                        let currentRotation = startRotationDegrees + diff
                        onDragChanged(currentRotation)
                    }
                    .onEnded { value in
                        let frame = geometry.frame(in: .global)
                        guard !Self.isInBottomDeadZone(value.startLocation, frame: frame, maxInteractiveGlobalY: maxInteractiveGlobalY),
                              let dragStartAngle else {
                            self.dragStartAngle = nil
                            return
                        }

                        let center = CGPoint(x: diameter / 2, y: diameter / 2)
                        let currentLocation = Self.clampedPoint(
                            value.location,
                            frame: frame,
                            maxInteractiveGlobalY: maxInteractiveGlobalY
                        )
                        let predictedLocation = Self.clampedPoint(
                            value.predictedEndLocation,
                            frame: frame,
                            maxInteractiveGlobalY: maxInteractiveGlobalY
                        )
                        let currentAngle = Self.angleDegrees(point: currentLocation, center: center)
                        let predictedAngle = Self.angleDegrees(point: predictedLocation, center: center)
                        let currentDiff = Self.normalizedDeltaDegrees(from: dragStartAngle, to: currentAngle)
                        let predictedDiff = Self.normalizedDeltaDegrees(from: dragStartAngle, to: predictedAngle)
                        let currentRotation = startRotationDegrees + currentDiff
                        let predictedRotation = startRotationDegrees + predictedDiff

                        self.dragStartAngle = nil
                        startRotationDegrees = currentRotation
                        onDragEnded(currentRotation, predictedRotation)
                    }
            )
        }
        .frame(width: diameter, height: diameter)
        .onChange(of: resetSignal) { _, _ in
            dragStartAngle = nil
            startRotationDegrees = rotationDegrees
        }
    }

    private static func angleDegrees(point: CGPoint, center: CGPoint) -> Double {
        let dx = point.x - center.x
        let dy = point.y - center.y
        return atan2(dy, dx) * 180 / .pi
    }

    private static func normalizedDeltaDegrees(from start: Double, to current: Double) -> Double {
        var delta = current - start
        while delta > 180 { delta -= 360 }
        while delta < -180 { delta += 360 }
        return delta
    }

    private static func isInBottomDeadZone(
        _ point: CGPoint,
        frame: CGRect,
        maxInteractiveGlobalY: CGFloat
    ) -> Bool {
        (frame.minY + point.y) > maxInteractiveGlobalY
    }

    private static func clampedPoint(
        _ point: CGPoint,
        frame: CGRect,
        maxInteractiveGlobalY: CGFloat
    ) -> CGPoint {
        let maxLocalY = maxInteractiveGlobalY - frame.minY
        return CGPoint(x: point.x, y: min(point.y, maxLocalY))
    }

    private static func tickIndex(for relativeStep: Int, centerTickIndex: Int) -> Int {
        // Positive relStep must be on the visual LEFT side of center.
        ((centerTickIndex - relativeStep) % tickCount + tickCount) % tickCount
    }

    private static func clampedOffsetSteps(_ offsetStepsSigned: Int) -> Int {
        max(-(tickCount - 1), min(tickCount - 1, offsetStepsSigned))
    }

    private static func isTickFilled(
        tick: Int,
        centerTickIndex: Int,
        offsetStepsSigned: Int
    ) -> Bool {
        let clamped = clampedOffsetSteps(offsetStepsSigned)
        guard clamped != 0 else { return false }
        let tickRelIndex = relativeStep(from: centerTickIndex, to: tick)

        if clamped > 0 {
            return tickRelIndex >= 0 && tickRelIndex <= clamped
        }

        return tickRelIndex <= 0 && tickRelIndex >= clamped
    }

    private static func filledTickIndices(centerTickIndex: Int, offsetStepsSigned: Int) -> Set<Int> {
        guard offsetStepsSigned != 0 else { return [] }
        return Set((0..<tickCount).filter { tick in
            isTickFilled(tick: tick, centerTickIndex: centerTickIndex, offsetStepsSigned: offsetStepsSigned)
        })
    }

    private static func activeCenterTickIndex(rotationDegrees: Double) -> Int {
        let degreesPerTick = 360.0 / Double(tickCount)
        let nearest = Int(((-rotationDegrees) / degreesPerTick).rounded())
        return ((nearest % tickCount) + tickCount) % tickCount
    }

    private static func relativeStep(from centerTickIndex: Int, to tickIndex: Int) -> Int {
        let half = tickCount / 2
        var delta = centerTickIndex - tickIndex
        delta = ((delta + half) % tickCount + tickCount) % tickCount - half
        return delta
    }

    private static func tickPath(
        tick: Int,
        center: CGPoint,
        outerRadius: CGFloat,
        fiveMinuteLength: CGFloat,
        tenMinuteLength: CGFloat,
        hourLength: CGFloat,
        minorWidth: CGFloat,
        majorWidth: CGFloat,
        lineWidth: CGFloat,
        degreesPerTick: Double,
        rotationDegrees: Double
    ) -> Path {
        let isHourTick = tick.isMultiple(of: Self.hourTickInterval)
        let isTenMinuteTick = tick.isMultiple(of: Self.tenMinuteTickInterval)
        let angleDegrees = (Double(tick) * degreesPerTick) + rotationDegrees - 90
        let angleRadians = angleDegrees * .pi / 180
        let angle = CGFloat(angleRadians)
        let cosAngle = CGFloat(cos(angleRadians))
        let sinAngle = CGFloat(sin(angleRadians))
        let length: CGFloat
        if isHourTick {
            length = hourLength
        } else if isTenMinuteTick {
            length = tenMinuteLength
        } else {
            length = fiveMinuteLength
        }
        let _ = isHourTick ? majorWidth : minorWidth
        let width = lineWidth

        let start = CGPoint(
            x: center.x + cosAngle * (outerRadius - length),
            y: center.y + sinAngle * (outerRadius - length)
        )
        let end = CGPoint(
            x: center.x + cosAngle * outerRadius,
            y: center.y + sinAngle * outerRadius
        )
        let mid = CGPoint(
            x: (start.x + end.x) / 2,
            y: (start.y + end.y) / 2
        )
        let localRect = CGRect(
            x: -length / 2,
            y: -width / 2,
            width: length,
            height: width
        )
        let roundedTick = Path(
            roundedRect: localRect,
            cornerSize: CGSize(width: 1, height: 1)
        )
        let transform = CGAffineTransform(translationX: mid.x, y: mid.y)
            .rotated(by: angle)
        return roundedTick.applying(transform)
    }
}
