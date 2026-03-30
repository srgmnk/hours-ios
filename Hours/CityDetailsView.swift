import SwiftUI

struct CityDetailsView: View {
    private enum DayType {
        case weekday
        case saturday
        case sunday
    }

    private enum TimePeriod {
        case deepNight
        case earlyHours
        case freshMorning
        case daytime
        case evening
        case lateHours
    }

    private struct VibeSummary {
        let title: String
        let subtitle: String
    }

    private struct OverlapPresentation {
        let text: AttributedString
        let opacity: Double
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme

    let city: City
    let primaryCity: City
    let date: Date

    private let weatherTitle = "Clear"
    private let weatherValue = "27"
    private let weatherUnit = "°C"
    private let weatherSecondary = "Feels like 33°C"
    private let sunTitle = "Sunset"
    private let sunValue = "18:42"
    private let sunSecondary = "Sunrise at 06:40"
    private let bottomLineText = "Waxing Gibbous. Next full moon in 4 days."
    private let horizontalPadding: CGFloat = 20
    private let cardSpacing: CGFloat = 12
    private let cardCornerRadius: CGFloat = 20

    private var headerTitle: String {
        CityTimeFormatter.formatDetailsHeader(date, in: city.timeZone)
    }

    private var vibeSummary: VibeSummary {
        let calendar = calendarForCity
        let weekday = calendar.component(.weekday, from: date)
        return summary(for: dayType(for: weekday), period: currentTimePeriod)
    }

    private var overlapPresentation: OverlapPresentation {
        if city.id == primaryCity.id {
            return OverlapPresentation(
                text: AttributedString("Working overlaps for other cities are calculated relative to this place"),
                opacity: 0.30
            )
        }

        let selectedWorkInterval = workInterval(for: city)
        let primaryWorkInterval = workInterval(for: primaryCity)
        let intersectionStart = max(selectedWorkInterval.start, primaryWorkInterval.start)
        let intersectionEnd = min(selectedWorkInterval.end, primaryWorkInterval.end)
        let hasOverlap = intersectionEnd > intersectionStart
        let offsetSeconds = city.timeZone.secondsFromGMT(for: date) - primaryCity.timeZone.secondsFromGMT(for: date)
        let firstLine = offsetDescription(offsetSeconds: offsetSeconds)

        if offsetSeconds == 0 {
            return OverlapPresentation(
                text: AttributedString(firstLine),
                opacity: 0.30
            )
        }

        if !hasOverlap {
            return OverlapPresentation(
                text: styledOverlapText(
                    "\(firstLine)\nNo working overlap today.",
                    offsetSeconds: offsetSeconds
                ),
                opacity: 0.84
            )
        }

        let overlapDuration = overlapDurationText(from: intersectionStart, to: intersectionEnd)
        let selectedTimeRange = "\(overlapTimeText(for: intersectionStart, in: city.timeZone))–\(overlapTimeText(for: intersectionEnd, in: city.timeZone)) \(city.displayName)"
        let fullText = "\(firstLine)\nOverlap today \(overlapDuration),\n\(selectedTimeRange)"
        return OverlapPresentation(
            text: styledOverlapText(
                fullText,
                offsetSeconds: offsetSeconds,
                additionalSemiboldTokens: [overlapDuration]
            ),
            opacity: 0.84
        )
    }

    private var currentTimePeriod: TimePeriod {
        let localHour = calendarForCity.component(.hour, from: date)
        return period(for: localHour)
    }

    private var calendarForCity: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = city.timeZone
        return calendar
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let bottomPadding = geometry.safeAreaInsets.bottom - 32

                VStack(spacing: 0) {
                    summaryBlock
                    infoBlock(bottomPadding: bottomPadding)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(SheetStyle.appScreenBackground(for: theme))
            }
            .navigationTitle(headerTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    closeButton
                }
            }
        }
    }

    private var summaryBlock: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            vibeIllustration

            VStack(spacing: 0) {
                Text(vibeSummary.title)
                    .font(.system(size: 32, weight: .medium))
                    .tracking(-0.96)
                    .foregroundStyle(theme.textPrimary.opacity(0.88))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(0)

                Text(vibeSummary.subtitle)
                    .font(.system(size: 32, weight: .medium))
                    .tracking(-0.96)
                    .foregroundStyle(theme.textPrimary.opacity(0.88))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(0)
            }
            .multilineTextAlignment(.center)
            .padding(.top, 28)
            .padding(.horizontal, 28)

            overlapText
                .padding(.top, 24)
                .padding(.horizontal, 32)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func infoBlock(bottomPadding: CGFloat) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: cardSpacing) {
                weatherCard
                sunCard
            }
            .padding(.horizontal, horizontalPadding)

            Text(bottomLineText)
                .font(.system(size: 14, weight: .regular))
                .tracking(-0.42)
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, 32)
                .padding(.horizontal, 32)
                .padding(.bottom, bottomPadding)
        }
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .medium))
        }
        .buttonStyle(.plain)
    }

    private func dayType(for weekday: Int) -> DayType {
        switch weekday {
        case 1:
            return .sunday
        case 7:
            return .saturday
        default:
            return .weekday
        }
    }

    private func period(for hour: Int) -> TimePeriod {
        switch hour {
        case 0..<6:
            return .deepNight
        case 6..<9:
            return .earlyHours
        case 9..<12:
            return .freshMorning
        case 12..<17:
            return .daytime
        case 17..<21:
            return .evening
        default:
            return .lateHours
        }
    }

    private func summary(for dayType: DayType, period: TimePeriod) -> VibeSummary {
        switch (dayType, period) {
        case (.weekday, .deepNight):
            return VibeSummary(title: "Deep night,", subtitle: "most people are\u{00A0}likely asleep")
        case (.weekday, .earlyHours):
            return VibeSummary(title: "Early hours,", subtitle: "the day is just about to\u{00A0}begin")
        case (.weekday, .freshMorning):
            return VibeSummary(title: "Fresh morning,", subtitle: "people are starting their\u{00A0}day")
        case (.weekday, .daytime):
            return VibeSummary(title: "Daytime,", subtitle: "most people are in the\u{00A0}middle of their day")
        case (.weekday, .evening):
            return VibeSummary(title: "Evening,", subtitle: "the workday is coming to\u{00A0}an\u{00A0}end")
        case (.weekday, .lateHours):
            return VibeSummary(title: "Late hours,", subtitle: "most people are likely relaxing")
        case (.saturday, .deepNight):
            return VibeSummary(title: "Deep night,", subtitle: "most people are likely asleep")
        case (.saturday, .earlyHours):
            return VibeSummary(title: "Early hours,", subtitle: "a quiet start to\u{00A0}the\u{00A0}day")
        case (.saturday, .freshMorning):
            return VibeSummary(title: "Fresh morning,", subtitle: "a slow and easy\u{00A0}morning")
        case (.saturday, .daytime):
            return VibeSummary(title: "Daytime,", subtitle: "a relaxed pace to\u{00A0}the\u{00A0}day")
        case (.saturday, .evening):
            return VibeSummary(title: "Evening,", subtitle: "the weekend is\u{00A0}winding down")
        case (.saturday, .lateHours):
            return VibeSummary(title: "Late hours,", subtitle: "people are getting ready for\u{00A0}the\u{00A0}week")
        case (.sunday, .deepNight):
            return VibeSummary(title: "Deep night,", subtitle: "most people are likely asleep")
        case (.sunday, .earlyHours):
            return VibeSummary(title: "Early hours,", subtitle: "a slower start to\u{00A0}the day")
        case (.sunday, .freshMorning):
            return VibeSummary(title: "Fresh morning,", subtitle: "people are easing into the\u{00A0}day")
        case (.sunday, .daytime):
            return VibeSummary(title: "Daytime,", subtitle: "free time and plans are\u{00A0}underway")
        case (.sunday, .evening):
            return VibeSummary(title: "Evening,", subtitle: "the evening is\u{00A0}just getting started")
        case (.sunday, .lateHours):
            return VibeSummary(title: "Late hours,", subtitle: "people are likely out or\u{00A0}unwinding")
        }
    }

    private var vibeIllustration: some View {
        Image(illustrationName(for: currentTimePeriod))
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 80, height: 100)
            .accessibilityHidden(true)
    }

    private func illustrationName(for period: TimePeriod) -> String {
        switch period {
        case .deepNight:
            return "city-deepnight"
        case .earlyHours:
            return "city-earlyhours"
        case .freshMorning:
            return "city-freshmorning"
        case .daytime:
            return "city-daytime"
        case .evening:
            return "city-evening"
        case .lateHours:
            return "city-latehours"
        }
    }

    private var overlapText: some View {
        Text(overlapPresentation.text)
        .font(.system(size: 18, weight: .regular))
        .tracking(-0.6)
        .multilineTextAlignment(.center)
        .foregroundStyle(theme.textPrimary.opacity(overlapPresentation.opacity))
        .lineSpacing(0)
    }

    private var weatherCard: some View {
        infoCard(
            title: weatherTitle,
            value: Text(weatherAttributedText)
                .tracking(-0.96),
            secondary: weatherSecondary,
            symbolName: "moon.stars.fill"
        )
    }

    private var sunCard: some View {
        infoCard(
            title: sunTitle,
            value: Text(sunValue)
                .font(.system(size: 32, weight: .medium))
                .tracking(-0.96),
            secondary: sunSecondary,
            symbolName: "sun.max.fill"
            )
    }

    private var weatherAttributedText: AttributedString {
        let fullText = "\(weatherValue)\(weatherUnit)"
        var attributed = AttributedString(fullText)
        var valueContainer = AttributeContainer()
        valueContainer.font = .system(size: 32, weight: .medium)
        var unitContainer = AttributeContainer()
        unitContainer.font = .system(size: 32, weight: .regular)

        if let valueRange = attributed.range(of: weatherValue) {
            attributed[valueRange].mergeAttributes(valueContainer)
        }

        if let unitRange = attributed.range(of: weatherUnit) {
            attributed[unitRange].mergeAttributes(unitContainer)
        }

        return attributed
    }

    private func workInterval(for city: City) -> DateInterval {
        let calendar = calendar(for: city.timeZone)
        let localComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let start = calendar.date(from: DateComponents(
            timeZone: city.timeZone,
            year: localComponents.year,
            month: localComponents.month,
            day: localComponents.day,
            hour: 9,
            minute: 0
        )) ?? date
        let end = calendar.date(from: DateComponents(
            timeZone: city.timeZone,
            year: localComponents.year,
            month: localComponents.month,
            day: localComponents.day,
            hour: 18,
            minute: 0
        )) ?? date
        return DateInterval(start: start, end: end)
    }

    private func offsetDescription(offsetSeconds: Int) -> String {
        if offsetSeconds == 0 {
            return "\(city.displayName) is in the same time zone as \(primaryCity.displayName)"
        }

        let direction = offsetSeconds > 0 ? "ahead of" : "behind"
        return "\(city.displayName) is \(offsetValueText(offsetSeconds: offsetSeconds)) \(direction) \(primaryCity.displayName)."
    }

    private func offsetValueText(offsetSeconds: Int) -> String {
        let totalMinutes = abs(offsetSeconds / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        let sign = offsetSeconds >= 0 ? "+" : "-"

        if minutes == 0 {
            return "\(sign)\(hours)h"
        }

        return String(format: "%@%d:%02d", sign, hours, minutes)
    }

    private func styledOverlapText(
        _ text: String,
        offsetSeconds: Int,
        additionalSemiboldTokens: [String] = []
    ) -> AttributedString {
        var attributed = AttributedString(text)
        var regularContainer = AttributeContainer()
        regularContainer.font = .system(size: 18, weight: .regular)
        attributed.mergeAttributes(regularContainer, mergePolicy: .keepNew)

        if offsetSeconds != 0,
           let offsetRange = attributed.range(of: offsetValueText(offsetSeconds: offsetSeconds)) {
            attributed[offsetRange].font = .system(size: 18, weight: .semibold)
        }

        for token in additionalSemiboldTokens {
            if let tokenRange = attributed.range(of: token) {
                attributed[tokenRange].font = .system(size: 18, weight: .semibold)
            }
        }

        return attributed
    }

    private func overlapDurationText(from start: Date, to end: Date) -> String {
        let totalMinutes = max(0, Int(end.timeIntervalSince(start) / 60))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if minutes == 0 {
            return "\(hours)h"
        }

        if hours == 0 {
            return "\(minutes)m"
        }

        return "\(hours)h \(minutes)m"
    }

    private func overlapTimeText(for date: Date, in timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func calendar(for timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    private func infoCard(
        title: String,
        value: Text,
        secondary: String,
        symbolName: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .tracking(-0.48)
                    .foregroundStyle(theme.textPrimary.opacity(0.95))

                Spacer(minLength: 0)

                Image(systemName: symbolName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(theme.textSecondary)
            }

            Spacer(minLength: 0)

            value
                .foregroundStyle(theme.textPrimary.opacity(0.84))

            Text(secondary)
                .font(.system(size: 14, weight: .regular))
                .tracking(-0.42)
                .foregroundStyle(theme.textSecondary)
                .padding(.top, 6)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, minHeight: 157, maxHeight: 157, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .fill(theme.surfaceCard)
        )
    }
}

#Preview {
    CityDetailsView(
        city: City(name: "Tokyo", timeZoneID: "Asia/Tokyo"),
        primaryCity: City(name: "Tokyo", timeZoneID: "Asia/Tokyo"),
        date: .now
    )
        .environment(\.appTheme, .light)
}
