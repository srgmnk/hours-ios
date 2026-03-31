import MapKit
import SwiftUI

private enum SunEventKind {
    case sunrise
    case sunset

    var title: String {
        switch self {
        case .sunrise:
            return "Sunrise"
        case .sunset:
            return "Sunset"
        }
    }

    var symbolName: String {
        switch self {
        case .sunrise:
            return "sunrise.fill"
        case .sunset:
            return "sunset.fill"
        }
    }
}

private struct SunPresentation {
    let primaryKind: SunEventKind
    let primaryDate: Date
    let secondaryKind: SunEventKind
    let secondaryDate: Date
}

private struct SunCardContent {
    let title: String
    let value: String
    let secondary: String
    let symbolName: String
}

private struct SunRequest: Sendable {
    let cityID: String
    let cityName: String
    let timeZoneID: String
    let timeZone: TimeZone
    let snapshotDate: Date
    let requestedAt: Date
    let isReferenceOffsetCity: Bool
}

private struct WeatherRequest: Sendable {
    let cityID: String
    let cityName: String
    let timeZoneID: String
    let snapshotDate: Date
    let requestedAt: Date
    let isReferenceOffsetCity: Bool
}

private struct WeatherCardContent: Sendable {
    let title: String
    let value: String
    let secondary: String
    let symbolName: String
}

private enum WeatherResolution: Sendable {
    case loaded(WeatherCardContent)
    case error
    case distantTime
}

private enum DaylightResolution: Sendable {
    case loaded(SunPresentation)
    case error
    case distantTime
}

private struct CardSkeletonShimmer: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { proxy in
                    let width = max(proxy.size.width, 1)
                    TimelineView(.animation) { timeline in
                        let duration = 1.4
                        let progress = timeline.date.timeIntervalSinceReferenceDate
                            .truncatingRemainder(dividingBy: duration) / duration
                        let offset = CGFloat(progress) * width * 2.2 - width * 1.1

                        LinearGradient(
                            colors: [
                                .clear,
                                Color.white.opacity(0.35),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: width * 0.85, height: proxy.size.height)
                        .offset(x: offset)
                    }
                }
                .mask(content)
                .allowsHitTesting(false)
            }
    }
}

struct CityDetailsView: View {
    private enum WeatherCardState {
        case loading
        case loaded(WeatherCardContent)
        case error
        case distantTime
    }

    private enum SunCardState {
        case loading
        case loaded(SunCardContent)
        case error
        case distantTime
    }

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

    private struct CityDetailsParallaxIllustrationView: View {
        let period: TimePeriod

        private let illustrationWidth: CGFloat = 353
        private let backStrength: CGFloat = 2
        private let middleStrength: CGFloat = 5
        private let frontStrength: CGFloat = 10

        var body: some View {
            LayeredParallaxIllustrationView(
                backImageName: "city-back",
                middleImageName: middleAssetName(for: period),
                frontImageName: "city-front",
                backStrength: backStrength,
                middleStrength: middleStrength,
                frontStrength: frontStrength
            )
            .frame(width: illustrationWidth)
            .accessibilityHidden(true)
        }

        private func middleAssetName(for period: TimePeriod) -> String {
            switch period {
            case .deepNight:
                return "city-mid-deepnight"
            case .earlyHours:
                return "city-mid-earlyhours"
            case .freshMorning:
                return "city-mid-freshmorning"
            case .daytime:
                return "city-mid-daytime"
            case .evening:
                return "city-mid-evening"
            case .lateHours:
                return "city-mid-latehours"
            }
        }
    }

    private struct VibeSummary {
        let lines: [String]
    }

    private struct OverlapPresentation {
        let text: AttributedString
        let opacity: Double
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @State private var weatherCardState: WeatherCardState = .loading
    @State private var sunCardState: SunCardState = .loading

    let city: City
    let primaryCity: City
    let date: Date
    let relativeOffsetMinutes: Int
    let cityViewPreference: CityViewPreference

    private let horizontalPadding: CGFloat = 8
    private let cardSpacing: CGFloat = 8
    private let cardCornerRadius: CGFloat = 20
    private static let weatherProvider = CityWeatherProvider()
    private static let sunEventProvider = CitySunEventProvider()

    private var headerTimeTitle: String {
        let formatter = DateFormatter()
        formatter.timeZone = city.timeZone
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private var headerDateTitle: String {
        let formatter = DateFormatter()
        formatter.timeZone = city.timeZone
        formatter.dateFormat = "d MMMM, EEEE"
        return formatter.string(from: date)
    }

    private var vibeSummary: VibeSummary {
        let calendar = calendarForCity
        let weekday = calendar.component(.weekday, from: date)
        return summary(for: dayType(for: weekday), period: currentTimePeriod)
    }

    private var cardResolutionTaskID: String {
        "\(city.id)|\(city.timeZoneID)|\(date.timeIntervalSinceReferenceDate)"
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
        let selectedTimeRange = "\(overlapTimeText(for: intersectionStart, in: city.timeZone))–\(overlapTimeText(for: intersectionEnd, in: city.timeZone)) \(city.name)"
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

    private var timeZoneDisplayText: String {
        CityTimeFormatter.formatUTCOffset(date, in: city.timeZone)
    }

    private var shouldShowDSTTag: Bool {
        guard !isZeroOffsetReferenceCity else { return false }
        return city.timeZone.isDaylightSavingTime(for: date)
    }

    private var isZeroOffsetReferenceCity: Bool {
        CustomReferenceOffsetOption.from(canonicalID: city.id) != nil ||
            CustomReferenceOffsetOption.from(timeZoneIdentifier: city.timeZoneID) != nil
    }

    private var relativeOffsetText: String {
        let sign = relativeOffsetMinutes >= 0 ? "+" : "-"
        let totalMinutes = abs(relativeOffsetMinutes)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return "\(sign)\(hours):" + String(format: "%02d", minutes)
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    closeButton
                }

                ToolbarItem(placement: .principal) {
                    VStack(spacing: 0) {
                        Text(headerTimeTitle)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(theme.textPrimary)

                        Text(headerDateTitle)
                            .font(.system(size: 14, weight: .medium))
                            .tracking(-0.42)
                            .foregroundStyle(theme.textPrimary.opacity(0.3))
                    }
                }
            }
        }
        .task(id: cardResolutionTaskID) {
            weatherCardState = .loading

            let request = WeatherRequest(
                cityID: city.id,
                cityName: city.name,
                timeZoneID: city.timeZoneID,
                snapshotDate: date,
                requestedAt: Date(),
                isReferenceOffsetCity: isZeroOffsetReferenceCity
            )

            let resolution = await Self.weatherProvider.resolve(for: request)
            switch resolution {
            case .loaded(let content):
                weatherCardState = .loaded(content)
            case .error:
                weatherCardState = .error
            case .distantTime:
                weatherCardState = .distantTime
            }
        }
        .task(id: cardResolutionTaskID) {
            sunCardState = .loading

            let request = SunRequest(
                cityID: city.id,
                cityName: city.name,
                timeZoneID: city.timeZoneID,
                timeZone: city.timeZone,
                snapshotDate: date,
                requestedAt: Date(),
                isReferenceOffsetCity: isZeroOffsetReferenceCity
            )

            let resolution = await Self.sunEventProvider.resolve(for: request)
            switch resolution {
            case .loaded(let presentation):
                sunCardState = .loaded(
                    SunCardContent(
                        title: presentation.primaryKind.title,
                        value: overlapTimeText(for: presentation.primaryDate, in: city.timeZone),
                        secondary: "\(presentation.secondaryKind.title) at \(overlapTimeText(for: presentation.secondaryDate, in: city.timeZone))",
                        symbolName: presentation.primaryKind.symbolName
                    )
                )
            case .error:
                sunCardState = .error
            case .distantTime:
                sunCardState = .distantTime
            }
        }
    }

    private var summaryBlock: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            vibeIllustration
                .padding(.top, -80)

            VStack(spacing: 0) {
                ForEach(Array(vibeSummary.lines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.system(size: 32, weight: .medium))
                        .tracking(-0.96)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, -6)
                }
            }
            .multilineTextAlignment(.center)
            .padding(.top, -24)
            .padding(.horizontal, 28)

            overlapText
                .padding(.top, 16)
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

            bottomLine
                .padding(.top, 32)
                .padding(.horizontal, 32)
                .padding(.bottom, bottomPadding)
        }
    }

    private var bottomLine: some View {
        HStack(spacing: 4) {
            if relativeOffsetMinutes != 0 {
                Text("\(relativeOffsetText) from now,")
                    .font(.system(size: 14, weight: .regular))
                    .tracking(-0.42)
                    .foregroundStyle(theme.textSecondary)
            }

            HStack(spacing: 4) {
                Text(timeZoneDisplayText)
                    .font(.system(size: 14, weight: .regular))
                    .tracking(-0.42)
                    .foregroundStyle(theme.textSecondary)

                if shouldShowDSTTag {
                    DSTBadgeView(cityViewPreference: cityViewPreference)
                }
            }
        }
        .frame(maxWidth: .infinity)
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
            return VibeSummary(lines: ["Deep night,", "most people are likely", "asleep"])
        case (.weekday, .earlyHours):
            return VibeSummary(lines: ["Early hours,", "the day is just about", "to begin"])
        case (.weekday, .freshMorning):
            return VibeSummary(lines: ["Fresh morning,", "people are starting", "their day"])
        case (.weekday, .daytime):
            return VibeSummary(lines: ["Daytime,", "most people are in", "the middle of their day"])
        case (.weekday, .evening):
            return VibeSummary(lines: ["Evening,", "the workday is coming", "to an end"])
        case (.weekday, .lateHours):
            return VibeSummary(lines: ["Late hours,", "most people are likely", "relaxing"])
        case (.saturday, .deepNight):
            return VibeSummary(lines: ["Deep night,", "most people are likely", "asleep"])
        case (.saturday, .earlyHours):
            return VibeSummary(lines: ["Early hours,", "a quiet start to", "the day"])
        case (.saturday, .freshMorning):
            return VibeSummary(lines: ["Fresh morning,", "a slow and easy", "morning"])
        case (.saturday, .daytime):
            return VibeSummary(lines: ["Daytime,", "a relaxed pace to", "the day"])
        case (.saturday, .evening):
            return VibeSummary(lines: ["Evening,", "the weekend is", "winding down"])
        case (.saturday, .lateHours):
            return VibeSummary(lines: ["Late hours,", "people are getting ready for", "the week"])
        case (.sunday, .deepNight):
            return VibeSummary(lines: ["Deep night,", "most people are likely", "asleep"])
        case (.sunday, .earlyHours):
            return VibeSummary(lines: ["Early hours,", "a slower start to", "the day"])
        case (.sunday, .freshMorning):
            return VibeSummary(lines: ["Fresh morning,", "people are easing into", "the day"])
        case (.sunday, .daytime):
            return VibeSummary(lines: ["Daytime,", "free time and plans", "are underway"])
        case (.sunday, .evening):
            return VibeSummary(lines: ["Evening,", "the evening is just", "getting started"])
        case (.sunday, .lateHours):
            return VibeSummary(lines: ["Late hours,", "people are likely out or", "unwinding"])
        }
    }

    private var vibeIllustration: some View {
        CityDetailsParallaxIllustrationView(period: currentTimePeriod)
    }

    private var overlapText: some View {
        Text(overlapPresentation.text)
        .font(.system(size: 16, weight: .regular))
        .tracking(-0.6)
        .multilineTextAlignment(.center)
        .foregroundStyle(theme.textPrimary.opacity(overlapPresentation.opacity))
        .lineSpacing(2)
    }

    @ViewBuilder
    private var weatherCard: some View {
        switch weatherCardState {
        case .loading:
            loadingInfoCard(title: "Weather")
        case .loaded(let content):
            infoCard(
                title: content.title,
                value: Text(weatherAttributedText(for: content.value))
                    .tracking(-0.96),
                secondary: content.secondary,
                symbolName: content.symbolName
            )
        case .error:
            statusInfoCard(
                title: "Weather",
                secondary: "Weather took a day off"
            )
        case .distantTime:
            statusInfoCard(
                title: "Weather",
                secondary: "Forecast not that far"
            )
        }
    }

    @ViewBuilder
    private var sunCard: some View {
        switch sunCardState {
        case .loading:
            loadingInfoCard(title: "Daylight")
        case .loaded(let content):
            infoCard(
                title: content.title,
                value: Text(content.value)
                    .font(.system(size: 32, weight: .medium))
                    .tracking(-0.96),
                secondary: content.secondary,
                symbolName: content.symbolName
            )
        case .error:
            statusInfoCard(
                title: "Daylight",
                secondary: "Sun is off duty"
            )
        case .distantTime:
            statusInfoCard(
                title: "Daylight",
                secondary: "Sun not scheduled yet"
            )
        }
    }

    private func weatherAttributedText(for text: String) -> AttributedString {
        var attributed = AttributedString(text)
        var valueContainer = AttributeContainer()
        valueContainer.font = .system(size: 32, weight: .medium)
        attributed.mergeAttributes(valueContainer, mergePolicy: .keepNew)

        guard let unitRange = attributed.range(of: "°C", options: .backwards) else {
            return attributed
        }

        attributed[unitRange].font = .system(size: 32, weight: .regular)

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
            return "\(city.name) is in the same time zone as \(primaryCity.name)"
        }

        let direction = offsetSeconds > 0 ? "ahead of" : "behind"
        return "\(city.name) is \(offsetValueText(offsetSeconds: offsetSeconds)) \(direction) \(primaryCity.name)."
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
        regularContainer.font = .system(size: 16, weight: .regular)
        attributed.mergeAttributes(regularContainer, mergePolicy: .keepNew)

        if offsetSeconds != 0,
           let offsetRange = attributed.range(of: offsetValueText(offsetSeconds: offsetSeconds)) {
            attributed[offsetRange].font = .system(size: 16, weight: .semibold)
        }

        for token in additionalSemiboldTokens {
            if let tokenRange = attributed.range(of: token) {
                attributed[tokenRange].font = .system(size: 16, weight: .semibold)
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
                    .foregroundStyle(theme.textPrimary.opacity(0.84))

                Spacer(minLength: 0)

                Image(systemName: symbolName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(theme.textSecondary)
                    .padding(.top, -3)
            }

            Spacer(minLength: 0)

            value
                .foregroundStyle(theme.textPrimary)

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

    private func loadingInfoCard(title: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .tracking(-0.48)
                .foregroundStyle(theme.textPrimary.opacity(0.30))

            Spacer(minLength: 0)

            skeletonBar(width: 92, height: 32)

            skeletonBar(width: 112, height: 14)
                .padding(.top, 12)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, minHeight: 157, maxHeight: 157, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .fill(theme.surfaceCard)
        )
    }

    private func skeletonBar(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(theme.textPrimary.opacity(0.03))
            .frame(width: width, height: height)
            .modifier(CardSkeletonShimmer())
    }

    private func statusInfoCard(title: String, secondary: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .tracking(-0.48)
                .foregroundStyle(theme.textPrimary.opacity(0.30))

            Spacer(minLength: 0)

            Text("—")
                .font(.system(size: 32, weight: .regular))
                .tracking(-0.96)
                .foregroundStyle(theme.textSecondary)

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

private actor CityWeatherProvider {
    private struct CoordinatePoint {
        let latitude: Double
        let longitude: Double
    }

    private struct WeatherPoint {
        let temperatureCelsius: Double
        let apparentTemperatureCelsius: Double
        let weatherCode: Int
    }

    private struct OpenMeteoWeatherResponse: Decodable {
        struct CurrentSnapshot: Decodable {
            let temperature2m: Double
            let apparentTemperature: Double
            let weatherCode: Int

            enum CodingKeys: String, CodingKey {
                case temperature2m = "temperature_2m"
                case apparentTemperature = "apparent_temperature"
                case weatherCode = "weather_code"
            }
        }

        struct HourlySnapshot: Decodable {
            let time: [String]
            let temperature2m: [Double]
            let apparentTemperature: [Double]
            let weatherCode: [Int]

            enum CodingKeys: String, CodingKey {
                case time
                case temperature2m = "temperature_2m"
                case apparentTemperature = "apparent_temperature"
                case weatherCode = "weather_code"
            }
        }

        let current: CurrentSnapshot?
        let hourly: HourlySnapshot?
    }

    private var coordinateCache: [String: CoordinatePoint] = [:]
    private let availabilityWindow: TimeInterval = 24 * 60 * 60
    private let currentWeatherThreshold: TimeInterval = 60

    func resolve(for request: WeatherRequest) async -> WeatherResolution {
        guard abs(request.snapshotDate.timeIntervalSince(request.requestedAt)) <= availabilityWindow else {
            return .distantTime
        }

        guard !request.isReferenceOffsetCity,
              let timeZone = TimeZone(identifier: request.timeZoneID),
              let coordinate = await coordinate(for: request) else {
            return .error
        }

        do {
            let response = try await fetchWeather(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                timeZoneID: request.timeZoneID
            )
            let isDaylight = isDaylight(at: request.snapshotDate, in: timeZone)

            if abs(request.snapshotDate.timeIntervalSince(request.requestedAt)) <= currentWeatherThreshold,
               let current = response.current {
                return .loaded(makeCardContent(
                    temperatureCelsius: current.temperature2m,
                    apparentTemperatureCelsius: current.apparentTemperature,
                    weatherCode: current.weatherCode,
                    isDaylight: isDaylight
                ))
            }

            if let hourlyPoint = nearestHourlyPoint(
                from: response.hourly,
                to: request.snapshotDate,
                in: timeZone
            ) {
                return .loaded(makeCardContent(
                    temperatureCelsius: hourlyPoint.temperatureCelsius,
                    apparentTemperatureCelsius: hourlyPoint.apparentTemperatureCelsius,
                    weatherCode: hourlyPoint.weatherCode,
                    isDaylight: isDaylight
                ))
            }
        } catch {
            return .error
        }

        return .error
    }

    private func coordinate(for request: WeatherRequest) async -> CoordinatePoint? {
        if let cached = coordinateCache[request.cityID] {
            return cached
        }

        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = request.cityName
        searchRequest.resultTypes = [.address]

        let response: MKLocalSearch.Response
        do {
            response = try await MKLocalSearch(request: searchRequest).start()
        } catch {
            return nil
        }

        let matchingItem =
            response.mapItems.first(where: { mapItem in
                let coordinate = mapItem.location.coordinate
                guard CLLocationCoordinate2DIsValid(coordinate) else {
                    return false
                }
                return mapItem.timeZone?.identifier == request.timeZoneID
            }) ??
            response.mapItems.first(where: { mapItem in
                let coordinate = mapItem.location.coordinate
                return CLLocationCoordinate2DIsValid(coordinate)
            })

        guard let coordinate = matchingItem?.location.coordinate,
              CLLocationCoordinate2DIsValid(coordinate) else {
            return nil
        }

        let point = CoordinatePoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
        coordinateCache[request.cityID] = point
        return point
    }

    private func fetchWeather(
        latitude: Double,
        longitude: Double,
        timeZoneID: String
    ) async throws -> OpenMeteoWeatherResponse {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.open-meteo.com"
        components.path = "/v1/forecast"
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "timezone", value: timeZoneID),
            URLQueryItem(
                name: "current",
                value: "temperature_2m,apparent_temperature,weather_code"
            ),
            URLQueryItem(
                name: "hourly",
                value: "temperature_2m,apparent_temperature,weather_code"
            ),
            URLQueryItem(name: "past_days", value: "1"),
            URLQueryItem(name: "forecast_days", value: "2")
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(OpenMeteoWeatherResponse.self, from: data)
    }

    private func nearestHourlyPoint(
        from hourly: OpenMeteoWeatherResponse.HourlySnapshot?,
        to snapshot: Date,
        in timeZone: TimeZone
    ) -> WeatherPoint? {
        guard let hourly else { return nil }

        let count = min(
            hourly.time.count,
            hourly.temperature2m.count,
            hourly.apparentTemperature.count,
            hourly.weatherCode.count
        )
        guard count > 0 else { return nil }

        var nearestPoint: WeatherPoint?
        var nearestDistance = TimeInterval.greatestFiniteMagnitude

        for index in 0..<count {
            guard let candidateDate = localDate(from: hourly.time[index], in: timeZone) else {
                continue
            }

            let distance = abs(candidateDate.timeIntervalSince(snapshot))
            guard distance < nearestDistance else { continue }

            nearestDistance = distance
            nearestPoint = WeatherPoint(
                temperatureCelsius: hourly.temperature2m[index],
                apparentTemperatureCelsius: hourly.apparentTemperature[index],
                weatherCode: hourly.weatherCode[index]
            )
        }

        return nearestPoint
    }

    private func localDate(from text: String, in timeZone: TimeZone) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone

        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        if let date = formatter.date(from: text) {
            return date
        }

        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter.date(from: text)
    }

    private func isDaylight(at date: Date, in timeZone: TimeZone) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let hour = calendar.component(.hour, from: date)
        return (6..<18).contains(hour)
    }

    private func makeCardContent(
        temperatureCelsius: Double,
        apparentTemperatureCelsius: Double,
        weatherCode: Int,
        isDaylight: Bool
    ) -> WeatherCardContent {
        WeatherCardContent(
            title: title(for: weatherCode),
            value: temperatureText(for: temperatureCelsius),
            secondary: "Feels like \(temperatureText(for: apparentTemperatureCelsius))",
            symbolName: symbolName(for: weatherCode, isDaylight: isDaylight)
        )
    }

    private func temperatureText(for temperatureCelsius: Double) -> String {
        "\(Int(temperatureCelsius.rounded()))°C"
    }

    private func title(for weatherCode: Int) -> String {
        switch weatherCode {
        case 0:
            return "Clear"
        case 1:
            return "Mainly clear"
        case 2:
            return "Partly cloudy"
        case 3:
            return "Cloudy"
        case 45, 48:
            return "Fog"
        case 51, 53, 55:
            return "Drizzle"
        case 56, 57:
            return "Freezing drizzle"
        case 61, 63, 65, 66, 67, 80, 81, 82:
            return "Rain"
        case 71, 73, 75, 77, 85, 86:
            return "Snow"
        case 95, 96, 99:
            return "Thunderstorm"
        default:
            return "Unknown"
        }
    }

    private func symbolName(for weatherCode: Int, isDaylight: Bool) -> String {
        switch weatherCode {
        case 0:
            return isDaylight ? "sun.max.fill" : "moon.stars.fill"
        case 1, 2:
            return isDaylight ? "cloud.sun.fill" : "cloud.moon.fill"
        case 3:
            return "cloud.fill"
        case 45, 48:
            return "cloud.fog.fill"
        case 51, 53, 55, 56, 57:
            return "cloud.drizzle.fill"
        case 61, 63, 65, 66, 67, 80, 81, 82:
            return "cloud.rain.fill"
        case 71, 73, 75, 77, 85, 86:
            return "cloud.snow.fill"
        case 95, 96, 99:
            return "cloud.bolt.rain.fill"
        default:
            return "cloud.fill"
        }
    }
}

private actor CitySunEventProvider {
    private struct SunEvents {
        let sunrise: Date
        let sunset: Date
    }

    private var coordinateCache: [String: CLLocationCoordinate2D] = [:]
    private let availabilityWindow: TimeInterval = 10 * 365 * 24 * 60 * 60

    func resolve(for request: SunRequest) async -> DaylightResolution {
        guard abs(request.snapshotDate.timeIntervalSince(request.requestedAt)) <= availabilityWindow else {
            return .distantTime
        }

        guard !request.isReferenceOffsetCity,
              let coordinate = await coordinate(for: request) else {
            return .error
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = request.timeZone

        guard let currentDayEvents = sunEvents(
            for: request.snapshotDate,
            coordinate: coordinate,
            timeZone: request.timeZone,
            calendar: calendar
        ) else {
            return .error
        }

        if request.snapshotDate < currentDayEvents.sunrise {
            return .loaded(SunPresentation(
                primaryKind: .sunrise,
                primaryDate: currentDayEvents.sunrise,
                secondaryKind: .sunset,
                secondaryDate: currentDayEvents.sunset
            ))
        }

        if request.snapshotDate < currentDayEvents.sunset {
            guard let nextLocalDay = calendar.date(byAdding: .day, value: 1, to: request.snapshotDate),
                  let nextDayEvents = sunEvents(
                    for: nextLocalDay,
                    coordinate: coordinate,
                    timeZone: request.timeZone,
                    calendar: calendar
                  ) else {
                return .error
            }

            return .loaded(SunPresentation(
                primaryKind: .sunset,
                primaryDate: currentDayEvents.sunset,
                secondaryKind: .sunrise,
                secondaryDate: nextDayEvents.sunrise
            ))
        }

        guard let nextLocalDay = calendar.date(byAdding: .day, value: 1, to: request.snapshotDate),
              let nextDayEvents = sunEvents(
                for: nextLocalDay,
                coordinate: coordinate,
                timeZone: request.timeZone,
                calendar: calendar
              ) else {
            return .error
        }

        return .loaded(SunPresentation(
            primaryKind: .sunrise,
            primaryDate: nextDayEvents.sunrise,
            secondaryKind: .sunset,
            secondaryDate: nextDayEvents.sunset
        ))
    }

    private func coordinate(for request: SunRequest) async -> CLLocationCoordinate2D? {
        if let cached = coordinateCache[request.cityID] {
            return cached
        }

        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = request.cityName
        searchRequest.resultTypes = [.address]

        let response: MKLocalSearch.Response
        do {
            response = try await MKLocalSearch(request: searchRequest).start()
        } catch {
            return nil
        }

        let matchingItem =
            response.mapItems.first(where: { mapItem in
                let coordinate = mapItem.location.coordinate
                guard CLLocationCoordinate2DIsValid(coordinate) else {
                    return false
                }
                return mapItem.timeZone?.identifier == request.timeZoneID
            }) ??
            response.mapItems.first(where: { mapItem in
                let coordinate = mapItem.location.coordinate
                guard CLLocationCoordinate2DIsValid(coordinate) else {
                    return false
                }
                return true
            })

        let coordinate = matchingItem?.location.coordinate
        guard let coordinate, CLLocationCoordinate2DIsValid(coordinate) else {
            return nil
        }

        coordinateCache[request.cityID] = coordinate
        return coordinate
    }

    private func sunEvents(
        for date: Date,
        coordinate: CLLocationCoordinate2D,
        timeZone: TimeZone,
        calendar: Calendar
    ) -> SunEvents? {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = components.year,
              let month = components.month,
              let day = components.day else {
            return nil
        }

        let noon = calendar.date(from: DateComponents(
            timeZone: timeZone,
            year: year,
            month: month,
            day: day,
            hour: 12
        )) ?? date
        let timeZoneOffsetMinutes = Double(timeZone.secondsFromGMT(for: noon)) / 60.0

        guard let sunrise = solarEventDate(
            year: year,
            month: month,
            day: day,
            coordinate: coordinate,
            timeZone: timeZone,
            timeZoneOffsetMinutes: timeZoneOffsetMinutes,
            calendar: calendar,
            isSunrise: true
        ),
        let sunset = solarEventDate(
            year: year,
            month: month,
            day: day,
            coordinate: coordinate,
            timeZone: timeZone,
            timeZoneOffsetMinutes: timeZoneOffsetMinutes,
            calendar: calendar,
            isSunrise: false
        ) else {
            return nil
        }

        return SunEvents(sunrise: sunrise, sunset: sunset)
    }

    private func solarEventDate(
        year: Int,
        month: Int,
        day: Int,
        coordinate: CLLocationCoordinate2D,
        timeZone: TimeZone,
        timeZoneOffsetMinutes: Double,
        calendar: Calendar,
        isSunrise: Bool
    ) -> Date? {
        let julianDay = julianDay(year: year, month: month, day: day)
        let julianCentury = julianCentury(from: julianDay)
        let equationOfTime = equationOfTime(for: julianCentury)
        let solarDeclination = solarDeclination(for: julianCentury)

        guard let hourAngle = hourAngleSunrise(
            latitude: coordinate.latitude,
            solarDeclination: solarDeclination
        ) else {
            return nil
        }

        let signedHourAngle = isSunrise ? hourAngle : -hourAngle
        var localMinutes = 720 - 4 * (coordinate.longitude + signedHourAngle) - equationOfTime + timeZoneOffsetMinutes
        localMinutes.formTruncatingRemainder(dividingBy: 1_440)
        if localMinutes < 0 {
            localMinutes += 1_440
        }

        guard let startOfDay = calendar.date(from: DateComponents(
            timeZone: timeZone,
            year: year,
            month: month,
            day: day
        )) else {
            return nil
        }

        return startOfDay.addingTimeInterval(localMinutes * 60)
    }

    private func julianDay(year: Int, month: Int, day: Int) -> Double {
        var resolvedYear = year
        var resolvedMonth = month

        if resolvedMonth <= 2 {
            resolvedYear -= 1
            resolvedMonth += 12
        }

        let a = floor(Double(resolvedYear) / 100.0)
        let b = 2 - a + floor(a / 4.0)

        return floor(365.25 * Double(resolvedYear + 4716))
            + floor(30.6001 * Double(resolvedMonth + 1))
            + Double(day)
            + b
            - 1524.5
    }

    private func julianCentury(from julianDay: Double) -> Double {
        (julianDay - 2_451_545.0) / 36_525.0
    }

    private func equationOfTime(for julianCentury: Double) -> Double {
        let epsilon = degreesToRadians(obliquityCorrection(for: julianCentury))
        let geomMeanLongSun = degreesToRadians(geometricMeanLongitudeSun(for: julianCentury))
        let geomMeanAnomalySun = degreesToRadians(geometricMeanAnomalySun(for: julianCentury))
        let eccentricity = eccentricityEarthOrbit(for: julianCentury)
        let y = pow(tan(epsilon / 2.0), 2)

        let sin2L0 = sin(2.0 * geomMeanLongSun)
        let sinM = sin(geomMeanAnomalySun)
        let cos2L0 = cos(2.0 * geomMeanLongSun)
        let sin4L0 = sin(4.0 * geomMeanLongSun)
        let sin2M = sin(2.0 * geomMeanAnomalySun)

        let equation = y * sin2L0
            - 2.0 * eccentricity * sinM
            + 4.0 * eccentricity * y * sinM * cos2L0
            - 0.5 * y * y * sin4L0
            - 1.25 * eccentricity * eccentricity * sin2M

        return radiansToDegrees(equation) * 4.0
    }

    private func solarDeclination(for julianCentury: Double) -> Double {
        let correctedObliquity = degreesToRadians(obliquityCorrection(for: julianCentury))
        let apparentLongitude = degreesToRadians(sunApparentLongitude(for: julianCentury))
        return radiansToDegrees(asin(sin(correctedObliquity) * sin(apparentLongitude)))
    }

    private func hourAngleSunrise(latitude: Double, solarDeclination: Double) -> Double? {
        let latitudeRadians = degreesToRadians(latitude)
        let declinationRadians = degreesToRadians(solarDeclination)
        let zenithRadians = degreesToRadians(90.833)

        let cosineHourAngle = (
            cos(zenithRadians) / (cos(latitudeRadians) * cos(declinationRadians))
        ) - tan(latitudeRadians) * tan(declinationRadians)

        guard cosineHourAngle >= -1.0, cosineHourAngle <= 1.0 else {
            return nil
        }

        return radiansToDegrees(acos(cosineHourAngle))
    }

    private func geometricMeanLongitudeSun(for julianCentury: Double) -> Double {
        let rawValue = 280.46646 + julianCentury * (36_000.76983 + julianCentury * 0.0003032)
        return normalizeDegrees(rawValue)
    }

    private func geometricMeanAnomalySun(for julianCentury: Double) -> Double {
        357.52911 + julianCentury * (35_999.05029 - 0.0001537 * julianCentury)
    }

    private func eccentricityEarthOrbit(for julianCentury: Double) -> Double {
        0.016708634 - julianCentury * (0.000042037 + 0.0000001267 * julianCentury)
    }

    private func sunEquationOfCenter(for julianCentury: Double) -> Double {
        let anomalyRadians = degreesToRadians(geometricMeanAnomalySun(for: julianCentury))
        let sinMeanAnomaly = sin(anomalyRadians)
        let sinDoubleMeanAnomaly = sin(2.0 * anomalyRadians)
        let sinTripleMeanAnomaly = sin(3.0 * anomalyRadians)

        return sinMeanAnomaly * (1.914602 - julianCentury * (0.004817 + 0.000014 * julianCentury))
            + sinDoubleMeanAnomaly * (0.019993 - 0.000101 * julianCentury)
            + sinTripleMeanAnomaly * 0.000289
    }

    private func sunTrueLongitude(for julianCentury: Double) -> Double {
        geometricMeanLongitudeSun(for: julianCentury) + sunEquationOfCenter(for: julianCentury)
    }

    private func sunApparentLongitude(for julianCentury: Double) -> Double {
        let omega = 125.04 - 1934.136 * julianCentury
        return sunTrueLongitude(for: julianCentury) - 0.00569 - 0.00478 * sin(degreesToRadians(omega))
    }

    private func meanObliquityOfEcliptic(for julianCentury: Double) -> Double {
        let seconds = 21.448 - julianCentury * (46.815 + julianCentury * (0.00059 - julianCentury * 0.001813))
        return 23.0 + (26.0 + (seconds / 60.0)) / 60.0
    }

    private func obliquityCorrection(for julianCentury: Double) -> Double {
        let omega = 125.04 - 1934.136 * julianCentury
        return meanObliquityOfEcliptic(for: julianCentury) + 0.00256 * cos(degreesToRadians(omega))
    }

    private func normalizeDegrees(_ value: Double) -> Double {
        var normalized = value.truncatingRemainder(dividingBy: 360.0)
        if normalized < 0 {
            normalized += 360.0
        }
        return normalized
    }

    private func degreesToRadians(_ degrees: Double) -> Double {
        degrees * .pi / 180.0
    }

    private func radiansToDegrees(_ radians: Double) -> Double {
        radians * 180.0 / .pi
    }
}

private struct CityDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        CityDetailsView(
            city: City(name: "Tokyo", timeZoneID: "Asia/Tokyo"),
            primaryCity: City(name: "Tokyo", timeZoneID: "Asia/Tokyo"),
            date: .now,
            relativeOffsetMinutes: 0,
            cityViewPreference: .basic
        )
        .environment(\.appTheme, .light)
    }
}
