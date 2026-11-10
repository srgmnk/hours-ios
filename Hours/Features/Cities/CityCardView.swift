import SwiftUI
import Combine

struct CityCardView: View {
    @Environment(\.appTheme) private var theme
    let city: City
    let selectedInstant: Date
    let referenceTimeZone: TimeZone
    let isCurrent: Bool
    var isUserCurrentLocation: Bool = false
    var cityViewPreference: CityViewPreference = .basic
    let cardBackgroundColor: Color
    var showsActions = false
    var actionPresentation: CardsActionPresentation? = nil
    var onRename: () -> Void = {}
    var onDelete: () -> Void = {}
    var onOpenDetails: () -> Void = {}

    private var titleColor: Color { theme.accent }
    private var secondaryTextColor: Color { theme.textSecondary }
    private let basicMeridiemLabelXOffset: CGFloat = 76
    private let basicMeridiemLabelYOffset: CGFloat = 12
    private let compactMeridiemLabelXOffset: CGFloat = 52
    private let compactMeridiemLabelYOffset: CGFloat = 7

    private var timeComponents: CityTimeFormatter.TimeComponents {
        CityTimeFormatter.formatTimeComponents(selectedInstant, in: city.timeZone)
    }

    private var dateText: String {
        CityTimeFormatter.formatDate(selectedInstant, in: city.timeZone)
    }

    private var utcOffsetValueText: String {
        CityTimeFormatter.formatUTCOffsetValue(selectedInstant, in: city.timeZone)
    }

    private var shouldShowDSTTag: Bool {
        guard !isZeroOffsetReferenceCity else { return false }
        return city.timeZone.isDaylightSavingTime(for: selectedInstant)
    }

    private var isZeroOffsetReferenceCity: Bool {
        CustomReferenceOffsetOption.from(canonicalID: city.id) != nil ||
            CustomReferenceOffsetOption.from(timeZoneIdentifier: city.timeZoneID) != nil
    }

    private var deltaDisplay: (isPositive: Bool, text: String)? {
        guard !isCurrent else { return nil }
        let cityOffsetSeconds = city.timeZone.secondsFromGMT(for: selectedInstant)
        let referenceOffsetSeconds = referenceTimeZone.secondsFromGMT(for: selectedInstant)
        let deltaSeconds = cityOffsetSeconds - referenceOffsetSeconds
        let isPositive = deltaSeconds >= 0
        let totalMinutes = abs(deltaSeconds / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if minutes == 0 {
            return (isPositive, "\(hours)h")
        }

        return (isPositive, String(format: "%d:%02d", hours, minutes))
    }

    private var deltaText: String {
        if isCurrent {
            return "Primary"
        }
        return deltaDisplay?.text ?? "0h"
    }

    private var deltaSymbolName: String {
        guard let deltaDisplay else { return "" }
        return deltaDisplay.isPositive
            ? "plus.arrow.trianglehead.clockwise"
            : "minus.arrow.trianglehead.counterclockwise"
    }

    private var dayNightSymbol: String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = city.timeZone
        let hour = calendar.component(.hour, from: selectedInstant)
        return (8..<20).contains(hour) ? "sun.max.fill" : "moon.stars.fill"
    }

    var accessibilitySummary: String {
        [city.displayName, CityTimeFormatter.formatTime(selectedInstant, in: city.timeZone),
         dateText, dayNightSymbol == "sun.max.fill" ? "Day" : "Night", deltaAccessibilityLabel,
         CityTimeFormatter.formatUTCOffset(selectedInstant, in: city.timeZone),
         shouldShowDSTTag ? "Daylight saving time" : nil].compactMap { $0 }.joined(separator: ", ")
    }

    private var cardHeight: CGFloat {
        cityViewPreference == .cards ? 200 : (cityViewPreference == .compact ? 88 : 140)
    }

    var body: some View {
        Group {
            switch cityViewPreference {
            case .basic:
                basicLayout
            case .compact:
                compactLayout
            case .cards:
                cardsLayout
                    .accessibilityElement(children: showsActions ? .contain : .combine)
                    .accessibilityAction(named: "Rename", onRename)
                    .accessibilityAction(named: "Delete", onDelete)
                    .accessibilityAction(named: "City Details", onOpenDetails)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: cardHeight)
        .background(cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // Figma 761:10914: 18pt vertical / 20pt horizontal insets, 17pt header
    // and footer, centered 74pt time/date block in a fixed 200pt card.
    private var cardsLayout: some View {
        VStack(spacing: 0) {
            cityTitle(fontSize: 14, locationSize: 13)
                .frame(height: 17)
                .padding(.horizontal, 20)
            Spacer(minLength: 0)
            CardsActionRegion(presentation: actionPresentation ?? CardsActionPresentation(open: showsActions)) {
                VStack(spacing: 0) {
                    ViewThatFits(in: .horizontal) {
                        cardsTime(size: 48, tracking: 0)
                        cardsTime(size: 48, tracking: -1)
                        cardsTime(size: 44, tracking: -1)
                    }
                    .foregroundStyle(theme.variant == .light ? Color.black : theme.textPrimary)
                    .frame(height: 57)
                    HStack(spacing: 2) {
                        dayNightIcon(size: 14, weight: .medium)
                        Text(dateText)
                            .font(.system(size: 14, weight: .medium))
                            .tracking(-0.42)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                    .foregroundStyle(secondaryTextColor)
                    .frame(height: 17)
                }
            } rename: {
                cardAction("Rename", symbol: "character.textbox", color: theme.textPrimary,
                           foreground: theme.textInverse, action: onRename)
            } delete: {
                cardAction("Delete", symbol: "trash.fill", color: theme.accent,
                           foreground: .white, action: onDelete)
            }
            .frame(height: 74)
            Spacer(minLength: 0)
            ViewThatFits(in: .horizontal) {
                cardsFooter(size: 14)
                cardsFooter(size: 13)
                cardsFooter(size: 12)
                cardsFooter(size: 11)
                cardsFooter(size: 10)
                cardsFooter(size: 9)
                cardsFooter(size: 9, tracking: -0.7)
            }
            .frame(height: 17)
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 18)
    }

    private func cardsTime(size: CGFloat, tracking: CGFloat) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(timeComponents.numeric)
                .font(.system(size: size, weight: .medium))
                .monospacedDigit()
                .tracking(tracking)
            if let meridiem = timeComponents.meridiem {
                Text(meridiem).font(.system(size: 10, weight: .medium))
            }
        }
        .fixedSize()
    }

    // Fixed intrinsic text widths let ViewThatFits choose the largest complete
    // footer, rather than accepting an apparently fitting but truncated row.
    private func cardsFooter(size: CGFloat, tracking: CGFloat = -0.42) -> some View {
        HStack(spacing: 0) {
            HStack(spacing: 2) {
                Text(deltaText)
                if !isCurrent {
                    Image(systemName: deltaSymbolName)
                        .font(.system(size: size * 12 / 14, weight: .regular))
                        .offset(y: -0.5)
                }
            }
            .fixedSize()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(deltaAccessibilityLabel)
            Spacer(minLength: 4)
            HStack(spacing: 4) {
                Text("UTC" + utcOffsetValueText)
                if shouldShowDSTTag {
                    Text("DST")
                        .font(.system(size: size * 10 / 14, weight: .bold, design: .rounded))
                        .tracking(-0.2)
                        .padding(.horizontal, 5)
                        .padding(.bottom, 0.5)
                        .frame(height: 17)
                        .background(RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(theme.borderSubtle, lineWidth: 1))
                }
            }
            .fixedSize()
        }
        .font(.system(size: size, weight: .regular))
        .tracking(tracking)
        .foregroundStyle(secondaryTextColor)
    }

    private func cardAction(_ title: String, symbol: String, color: Color,
                            foreground: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: CardsActionMetrics.symbolPointSize, weight: .regular))
                .imageScale(.medium)
                .offset(y: CardsActionMetrics.symbolVerticalOffset)
                .foregroundStyle(foreground)
                .frame(width: CardsActionMetrics.diameter, height: CardsActionMetrics.diameter)
                .background(color, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) \(city.displayName)")
        .accessibilityIdentifier("city.\(title.lowercased()).\(city.id)")
    }

    private var basicLayout: some View {
        ZStack {
            VStack(spacing: 0) {
                cityTitle(fontSize: 14, locationSize: 12)
                    .padding(.top, 16)

                ZStack {
                    Text(timeComponents.numeric)
                        .font(.system(size: 48, weight: .medium))
                        .monospacedDigit()
                        .tracking(-1)
                        .foregroundStyle(theme.textPrimary)

                    if let meridiem = timeComponents.meridiem {
                        Text(meridiem)
                            .font(.system(size: 14, weight: .medium))
                            .tracking(-0.42)
                            .foregroundStyle(theme.textPrimary)
                            .offset(x: basicMeridiemLabelXOffset, y: basicMeridiemLabelYOffset)
                    }
                }
                .padding(.top, 4)
                .offset(y: 3)

                Spacer(minLength: 0)
            }

            VStack {
                Spacer()

                HStack {
                    basicDeltaView

                    Spacer(minLength: 0)

                    trailingTimezone
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }

            VStack {
                Spacer()
                HStack(spacing: 2) {
                    dayNightIcon(size: 14, weight: .medium)
                    Text(dateText)
                        .font(.system(size: 14, weight: .medium))
                        .tracking(-0.42)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .foregroundStyle(secondaryTextColor)
                .padding(.bottom, 16)
                .allowsHitTesting(false)
            }
        }
    }

    private var compactLayout: some View {
        GeometryReader { geometry in
            ZStack {
                compactTimeView
                    .offset(y: 12)

                VStack {
                    HStack {
                        dayNightIcon(size: 14, weight: .medium)

                        Spacer(minLength: 0)

                        compactDeltaView
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    Spacer(minLength: 0)

                    HStack(alignment: .lastTextBaseline) {
                        // Long localized dates wrap beside the centered time.
                        // Reserve the 20pt inset and 68pt for time/meridiem plus gap.
                        Text(dateText)
                            .font(.system(size: 14, weight: .medium))
                            .tracking(-0.42)
                            .foregroundStyle(secondaryTextColor)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                            .frame(width: max(0, geometry.size.width / 2 - 88), alignment: .leading)

                        Spacer(minLength: 0)

                        trailingTimezone
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }

                VStack(spacing: 0) {
                    cityTitle(fontSize: 14, locationSize: 10)
                        .padding(.top, 14)

                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var compactTimeView: some View {
        ZStack {
            Text(timeComponents.numeric)
                .font(.system(size: 32, weight: .medium))
                .monospacedDigit()
                .tracking(-0.64)
                .foregroundStyle(theme.textPrimary)

            if let meridiem = timeComponents.meridiem {
                Text(meridiem)
                    .font(.system(size: 12, weight: .medium))
                    .tracking(-0.24)
                    .foregroundStyle(theme.textPrimary)
                    .offset(x: compactMeridiemLabelXOffset, y: compactMeridiemLabelYOffset)
            }
        }
        .offset(y: 2)
    }

    private var basicDeltaView: some View {
        HStack(spacing: 2) {
            if isCurrent {
                Text(deltaText)
                    .font(.system(size: 14, weight: .regular))
                    .tracking(-0.42)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
            } else {
                Image(systemName: deltaSymbolName)
                    .font(.system(size: 12, weight: .regular))
                    .offset(y: -0.5)

                Text(deltaText)
                    .font(.system(size: 14, weight: .regular))
                    .tracking(-0.42)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
            }
        }
        .foregroundStyle(secondaryTextColor)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(deltaAccessibilityLabel)
    }

    private var compactDeltaView: some View {
        Group {
            if isCurrent {
                Text(deltaText)
                    .font(.system(size: 14, weight: .regular))
                    .tracking(-0.42)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
            } else {
                HStack(spacing: 2) {
                    Text(deltaText)
                        .font(.system(size: 14, weight: .regular))
                        .tracking(-0.42)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)

                    Image(systemName: deltaSymbolName)
                        .font(.system(size: 12, weight: .regular))
                        .offset(y: -0.5)
                }
            }
        }
        .foregroundStyle(secondaryTextColor)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(deltaAccessibilityLabel)
    }

    private var trailingTimezone: some View {
        HStack(spacing: 4) {
            HStack(spacing: 0) {
                Text("UTC")
                    .font(.system(size: 14, weight: .regular))
                    .tracking(-0.42)
                    .foregroundStyle(secondaryTextColor)
                Text(utcOffsetValueText)
                    .font(.system(size: 14, weight: .regular))
                    .tracking(-0.42)
                    .foregroundStyle(secondaryTextColor)
            }

            if shouldShowDSTTag {
                DSTBadgeView(cityViewPreference: cityViewPreference)
                    .environment(\.appTheme, theme)
            }
        }
    }

    private var deltaAccessibilityLabel: String {
        if isCurrent {
            return "Primary"
        }

        let hoursText = deltaText.replacingOccurrences(of: ":", with: " hours ")
        return (deltaDisplay?.isPositive == true ? "plus " : "minus ") + hoursText
    }

    private func cityTitle(fontSize: CGFloat, locationSize: CGFloat) -> some View {
        HStack(spacing: 4) {
            if isUserCurrentLocation {
                Image(systemName: "location.fill")
                    .font(.system(size: locationSize, weight: .semibold))
                    .foregroundStyle(titleColor)
            }

            Text(city.displayName)
                .font(.system(size: fontSize, weight: .semibold))
                .tracking(-0.42)
                .foregroundStyle(titleColor)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
    }

    private func dayNightIcon(size: CGFloat, weight: Font.Weight) -> some View {
        Image(systemName: dayNightSymbol)
            .font(.system(size: size, weight: weight))
            .foregroundStyle(secondaryTextColor)
    }
}

enum CardsActionMetrics {
    // Measured from the rendered Basic/Compact UIKit controls on iOS 27.1.
    static let diameter: CGFloat = 50
    static let spacing: CGFloat = 10
    static let symbolPointSize: CGFloat = 18
    // Match UIKit’s optical alignment (2 physical pixels upward at 3×).
    static let symbolVerticalOffset: CGFloat = -2 / 3
    static let centerOffset = (diameter + spacing) / 2
}

// Native trailing actions expand Delete first, then Rename. These intervals
// map the reference's two expansion phases onto the existing 96pt Cards swipe.
// Both directions sample the same curve; there are no delayed animations.
enum CardsActionExpansion {
    case rename, delete

    func progress(at swipeProgress: CGFloat) -> CGFloat {
        let interval: ClosedRange<CGFloat> = self == .delete ? 0...0.4 : 0.65...1
        return min(1, max(0, (swipeProgress - interval.lowerBound) /
                            (interval.upperBound - interval.lowerBound)))
    }
}

// Owned by a retained collection cell. Gesture updates invalidate only the
// central region; the title, footer, formatting and hosting configuration stay put.
final class CardsActionPresentation: ObservableObject {
    static let completionDuration = 0.22
    @Published private(set) var progress: CGFloat
    @Published private(set) var buttonsEnabled: Bool
    // Not published: sampling the rendered interpolation must not invalidate UI.
    var presentedProgress: CGFloat
    private var revision = 0

    init(open: Bool = false) {
        progress = open ? 1 : 0
        presentedProgress = open ? 1 : 0
        buttonsEnabled = open
    }

    // Retiring a hosting configuration can happen inside SwiftUI reconciliation.
    // Invalidate its completion without publishing to the outgoing view graph.
    func invalidateCompletion() {
        revision += 1
    }

    func updateInteractiveProgress(_ value: CGFloat) {
        revision += 1
        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            buttonsEnabled = false
            progress = min(1, max(0, value))
            presentedProgress = progress
        }
    }

    func settle(open: Bool, animated: Bool = true) {
        // Freeze any interrupted completion at its rendered value first.
        updateInteractiveProgress(presentedProgress)
        let currentRevision = revision
        let target: CGFloat = open ? 1 : 0
        guard animated else {
            updateInteractiveProgress(target)
            buttonsEnabled = open
            return
        }
        withAnimation(.easeOut(duration: Self.completionDuration), completionCriteria: .removed) {
            progress = target
        } completion: { [weak self] in
            guard let self, self.revision == currentRevision else { return }
            self.presentedProgress = target
            self.buttonsEnabled = open
        }
    }
}

private struct CardsActionRegion<Normal: View, Rename: View, Delete: View>: View {
    @ObservedObject var presentation: CardsActionPresentation
    let normal: Normal
    let rename: Rename
    let delete: Delete

    init(presentation: CardsActionPresentation, @ViewBuilder normal: () -> Normal,
         @ViewBuilder rename: () -> Rename, @ViewBuilder delete: () -> Delete) {
        self.presentation = presentation
        self.normal = normal()
        self.rename = rename()
        self.delete = delete()
    }

    var body: some View {
        CardsActionLayers(progress: presentation.progress, presentation: presentation,
                          normal: normal, rename: rename, delete: delete, buttonsEnabled: presentation.buttonsEnabled)
    }
}

private struct CardsActionLayers<Normal: View, Rename: View, Delete: View>: View, Animatable {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var progress: CGFloat
    let presentation: CardsActionPresentation
    let normal: Normal
    let rename: Rename
    let delete: Delete
    let buttonsEnabled: Bool

    var animatableData: CGFloat {
        get { progress }
        set {
            progress = newValue
            presentation.presentedProgress = newValue
        }
    }

    var body: some View {
        ZStack {
            normal
                .opacity(1 - progress)
                .offset(x: reduceMotion ? 0 : -12 * progress)
                .allowsHitTesting(false)
            HStack(spacing: CardsActionMetrics.spacing) {
                expanding(rename, action: .rename)
                expanding(delete, action: .delete)
            }
            .frame(height: 74)
            .allowsHitTesting(buttonsEnabled)
            .accessibilityHidden(!buttonsEnabled)
        }
    }

    private func expanding<V: View>(_ button: V, action: CardsActionExpansion) -> some View {
        let expansion = action.progress(at: progress)
        return button
            .opacity(expansion)
            .scaleEffect(reduceMotion ? 1 : expansion)
    }
}

struct DSTBadgeView: View {
    @Environment(\.appTheme) private var theme

    let cityViewPreference: CityViewPreference

    var body: some View {
        Text("DST")
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .tracking(cityViewPreference == .basic ? -0.9 : -0.2)
            .foregroundStyle(theme.textSecondary)
            .padding(.horizontal, 5)
            .padding(.bottom, 0.5)
            .frame(height: 17)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(theme.borderSubtle, lineWidth: 1)
            )
    }
}
