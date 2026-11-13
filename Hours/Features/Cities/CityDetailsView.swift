import EventKit
import EventKitUI
import CoreLocation
import SwiftUI
import UIKit
import UserNotifications

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
    let coordinate: LocalCityCoordinates.Coordinate?
    let timeZone: TimeZone
    let snapshotDate: Date
    let requestedAt: Date
    let isReferenceOffsetCity: Bool
}

private struct WeatherRequest: Sendable {
    let cityID: String
    let cityName: String
    let timeZoneID: String
    let coordinate: LocalCityCoordinates.Coordinate?
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
    @State private var showEventSheet = false
    @State private var showReminderTitleSheet = false
    @State private var eventStore = EKEventStore()
    @State private var reminderStore = EKEventStore()
    @State private var layout = CityDetailsLayoutObserver.Configuration()

    private var usesWideSummary: Bool { layout.usesWideSummary }

    // The native principal slot centers inside the safe toolbar area, which
    // excludes the right rail. Place the header beside Close in those narrow panes.
    private var usesLeadingHeader: Bool { layout.expandsContentSafeArea && presentingRailOnRight }

    let city: City
    let primaryCity: City
    let date: Date
    let relativeOffsetMinutes: Int
    let cityViewPreference: CityViewPreference
    var presentingRailOnRight = true

    private let horizontalPadding: CGFloat = 8
    private let cardSpacing: CGFloat = 8
    private let cardCornerRadius: CGFloat = 20
    private static let coordinateResolver = LegacyCityCoordinateResolver()
    private static let sunEventProvider = CitySunEventProvider()
    private static var weatherProvider = CityWeatherProvider(sunEventProvider: sunEventProvider)

    private var headerTimeTitle: String {
        let formatter = DateFormatter()
        formatter.timeZone = city.timeZone
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private var headerDateTitle: String {
        formattedHeaderDate(includingWeekday: true)
    }

    private var eventDateTitle: String {
        formattedHeaderDate(includingWeekday: false)
    }

    private var selectedCityOriginalName: String {
        city.name
    }

    private var referenceCityOriginalName: String {
        primaryCity.name
    }

    private var eventOffsetSeconds: Int {
        city.timeZone.secondsFromGMT(for: date) - primaryCity.timeZone.secondsFromGMT(for: date)
    }

    private var eventOffsetText: String {
        offsetValueText(offsetSeconds: eventOffsetSeconds)
    }

    private var creationNotesText: String {
        """
        Selected city: \(selectedCityOriginalName)
        Local time in \(selectedCityOriginalName): \(headerTimeTitle), \(eventDateTitle)
        Reference city: \(referenceCityOriginalName)
        Time difference: \(eventOffsetText)
        Created from Hours
        """
    }

    private var notificationBodyText: String {
        "\(headerTimeTitle) in \(selectedCityOriginalName) (\(referenceCityOriginalName) \(eventOffsetText))"
    }

    private func formattedHeaderDate(includingWeekday: Bool) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = city.timeZone
        formatter.dateFormat = includingWeekday ? "d MMMM, EEEE" : "d MMMM"
        return formatter.string(from: date)
    }

    private var vibeSummary: VibeSummary {
        let calendar = calendarForCity
        let weekday = calendar.component(.weekday, from: date)
        let summary = summary(for: dayType(for: weekday), period: currentTimePeriod)
        guard usesWideSummary else { return summary }
        return VibeSummary(lines: [summary.lines[0], summary.lines.dropFirst().joined(separator: " ")])
    }

    private var coordinateSnapshot: LocalCityCoordinates.Coordinate? {
        // Catalog geography is independent of Apple. Otherwise preserve the point
        // already associated with this saved city; never infer a new place from text.
        Self.coordinateResolver.catalogCoordinate(for: city)
            ?? Self.coordinateResolver.coordinate(for: city)
    }

    private var cardResolutionTaskID: String {
        let location = coordinateSnapshot.map { "\($0.latitude),\($0.longitude)" } ?? "unavailable"
        return "\(city.id)|\(city.timeZoneID)|\(location)|\(date.timeIntervalSinceReferenceDate)"
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
        let rangeSeparator = usesWideSummary ? " " : "\n"
        let fullText = "\(firstLine)\nOverlap today \(overlapDuration),\(rangeSeparator)\(selectedTimeRange)"
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

    private var calendarForCity: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = city.timeZone
        return calendar
    }

    var body: some View {
        let coordinate = coordinateSnapshot
        NavigationStack {
            GeometryReader { geometry in
                let spacing = CityDetailsFooterSpacing(
                    usesTwentyPointGaps: layout.usesTwentyPointFooterSpacing,
                    safeAreaBottom: geometry.safeAreaInsets.bottom)

                VStack(spacing: 0) {
                    summaryBlock
                        .padding(.bottom, spacing.summaryBottom)
                    infoBlock(bottomPadding: spacing.bottom, topSpacing: spacing.top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(SheetStyle.appScreenBackground(for: theme))
            }
            .modifier(CityDetailsContentSafeArea(
                enabled: layout.expandsContentSafeArea, railOnRight: layout.isInnerSplitView ? presentingRailOnRight : true))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    closeButton
                }

                ToolbarItem(placement: .topBarTrailing) {
                    createActionMenu
                }

                ToolbarItem(placement: usesLeadingHeader ? .topBarLeading : .principal) {
                    VStack(alignment: usesLeadingHeader ? .leading : .center, spacing: 0) {
                        Text(headerTimeTitle)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(theme.textPrimary)

                        Text(headerDateTitle)
                            .font(.system(size: 14, weight: .medium))
                            .tracking(-0.42)
                            .foregroundStyle(theme.textPrimary.opacity(0.3))
                    }
                    .fixedSize(horizontal: usesLeadingHeader, vertical: false)
                }
                .sharedBackgroundVisibility(usesLeadingHeader ? .hidden : .automatic)
            }
            .modifier(CityDetailsToolbarPlacement(keepsTopCorners: layout.isInnerSplitView && !presentingRailOnRight))
        }
        .background {
            CityDetailsLayoutObserver { layout = $0 }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .sheet(isPresented: $showEventSheet) {
            EventEditView(
                eventStore: eventStore,
                date: date,
                timeZone: city.timeZone,
                notes: creationNotesText
            )
        }
        .sheet(isPresented: $showReminderTitleSheet) {
            SingleTextEntrySheetView(
                title: "New reminder",
                initialText: "",
                placeholder: "Title",
                confirmButtonTitle: "Create",
                helperText: "We’ll create a new reminder in the Reminders app at your selected date and time",
                showsOriginalButton: false,
                onConfirm: { title in
                    DispatchQueue.main.async {
                        requestReminderAccessAndCreate(title: title)
                    }
                },
                onDismiss: {}
            )
        }
        .task(id: cardResolutionTaskID) {
            weatherCardState = .loading

            let request = WeatherRequest(
                cityID: city.id,
                cityName: city.name,
                timeZoneID: city.timeZoneID,
                coordinate: coordinate,
                snapshotDate: date,
                requestedAt: Date(),
                isReferenceOffsetCity: isZeroOffsetReferenceCity
            )

            let resolution = await Self.weatherProvider.resolve(for: request)
            guard !Task.isCancelled else { return }
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
                coordinate: coordinate,
                timeZone: city.timeZone,
                snapshotDate: date,
                requestedAt: Date(),
                isReferenceOffsetCity: isZeroOffsetReferenceCity
            )

            let resolution = await Self.sunEventProvider.resolve(for: request)
            guard !Task.isCancelled else { return }
            switch resolution {
            case .loaded(let presentation):
                sunCardState = .loaded(
                    SunCardContent(
                        title: presentation.primaryKind.title,
                        value: CityTimeFormatter.formatTime(presentation.primaryDate, in: city.timeZone),
                        secondary: "\(presentation.secondaryKind.title) at \(CityTimeFormatter.formatTime(presentation.secondaryDate, in: city.timeZone))",
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
        .offset(y: layout.summaryVerticalOffset)
    }

    private func infoBlock(bottomPadding: CGFloat, topSpacing: CGFloat = 32) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: cardSpacing) {
                weatherCard
                sunCard
            }
            .padding(.horizontal, horizontalPadding)

            bottomLine
                .padding(.top, topSpacing)
                .padding(.horizontal, 32)
                .padding(.bottom, bottomPadding)
        }
    }

    private var bottomLine: some View {
        CityDetailsFooter(
            timeZoneDisplayText: timeZoneDisplayText,
            shouldShowDSTTag: shouldShowDSTTag,
            cityViewPreference: cityViewPreference
        )
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .medium))
        }
        .buttonStyle(.plain)
    }

    private var createActionMenu: some View {
        Menu {
            Button {
                createCalendarEvent()
            } label: {
                Label("Add to calendar", systemImage: "calendar")
            }

            Button {
                createReminder()
            } label: {
                Label("Add a reminder", systemImage: "checklist")
            }

            Button {
                createPushNotification()
            } label: {
                Label("Push notification", systemImage: "app.badge")
            }
        } label: {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 14, weight: .medium))
                .padding(.top, 2)
        }
        .buttonStyle(.plain)
    }

    private func createCalendarEvent() {
        requestCalendarAccessAndPresent()
    }

    private func requestCalendarAccessAndPresent() {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess, .writeOnly, .authorized:
            showEventSheet = true
        case .notDetermined:
            if #available(iOS 17.0, *) {
                eventStore.requestWriteOnlyAccessToEvents { granted, _ in
                    DispatchQueue.main.async {
                        if granted {
                            showEventSheet = true
                        }
                    }
                }
            } else {
                eventStore.requestAccess(to: .event) { granted, _ in
                    DispatchQueue.main.async {
                        if granted {
                            showEventSheet = true
                        }
                    }
                }
            }
        case .restricted, .denied:
            break
        @unknown default:
            break
        }
    }

    private func createReminder() {
        showReminderTitleSheet = true
    }

    private func createPushNotification() {
        requestNotificationPermissionAndSchedule()
    }

    private func requestNotificationPermissionAndSchedule() {
        guard date > Date() else {
            return
        }

        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { @Sendable granted, _ in
            guard granted else {
                return
            }

            Task { @MainActor in
                schedulePushNotification(using: center)
            }
        }
    }

    private func schedulePushNotification(using center: UNUserNotificationCenter) {
        var components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        components.timeZone = .current

        let content = UNMutableNotificationContent()
        content.title = "Hours reminder"
        content.body = notificationBodyText
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        )

        center.add(request) { error in
            guard error == nil else {
                return
            }

            DispatchQueue.main.async {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
    }

    private func requestReminderAccessAndCreate(title: String) {
        switch EKEventStore.authorizationStatus(for: .reminder) {
        case .fullAccess, .writeOnly, .authorized:
            saveReminder(title: title)
        case .notDetermined:
            if #available(iOS 17.0, *) {
                reminderStore.requestFullAccessToReminders { granted, _ in
                    DispatchQueue.main.async {
                        if granted {
                            saveReminder(title: title)
                        }
                    }
                }
            } else {
                reminderStore.requestAccess(to: .reminder) { granted, _ in
                    DispatchQueue.main.async {
                        if granted {
                            saveReminder(title: title)
                        }
                    }
                }
            }
        case .restricted, .denied:
            break
        @unknown default:
            break
        }
    }

    private func saveReminder(title: String) {
        guard let calendar = reminderStore.defaultCalendarForNewReminders() else {
            return
        }

        let reminder = EKReminder(eventStore: reminderStore)
        reminder.title = title
        reminder.calendar = calendar
        reminder.notes = creationNotesText
        reminder.addAlarm(EKAlarm(absoluteDate: date))

        do {
            try reminderStore.save(reminder, commit: true)

            DispatchQueue.main.async {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        } catch {
            // Intentionally ignore reminder save failures for now.
        }
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
            .minimumScaleFactor(0.65)
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

    private struct ResponseKey: Hashable {
        let url: URL
        // past_days/forecast_days are relative to the service's local date.
        let localDay: Date
    }

    private struct CachedResponse {
        let response: OpenMeteoWeatherResponse
        let fetchedAt: Date
        var accessOrder: UInt64
    }

    private var responseCache: [ResponseKey: CachedResponse] = [:]
    private var inFlightResponses: [ResponseKey: Task<OpenMeteoWeatherResponse, Error>] = [:]
    private var responseAccessOrder: UInt64 = 0
    private let responseTTL: TimeInterval = 15 * 60
    private let responseCapacity = 16
    private let now: @Sendable () -> Date
    private let session: URLSession
    private let availabilityWindow: TimeInterval = 24 * 60 * 60
    private let currentWeatherThreshold: TimeInterval = 60
    private let sunEventProvider: CitySunEventProvider

    init(sunEventProvider: CitySunEventProvider, session: URLSession? = nil,
         now: @escaping @Sendable () -> Date = { Date() }) {
        self.sunEventProvider = sunEventProvider
        self.now = now
        if let session {
            self.session = session
        } else {
            // Only the bounded response cache below owns weather freshness.
            // Disable URLCache so an expired entry cannot be served from disk
            // or from a second HTTP cache with a different lifetime.
            let configuration = URLSessionConfiguration.ephemeral
            configuration.urlCache = nil
            configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
            self.session = URLSession(configuration: configuration)
        }
    }

    func resolve(for request: WeatherRequest) async -> WeatherResolution {
        guard abs(request.snapshotDate.timeIntervalSince(request.requestedAt)) <= availabilityWindow else {
            return .distantTime
        }

        guard !request.isReferenceOffsetCity,
              let timeZone = TimeZone(identifier: request.timeZoneID),
              let coordinate = request.coordinate,
              coordinate.latitude.isFinite, coordinate.longitude.isFinite,
              CLLocationCoordinate2DIsValid(CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)) else {
            return .error
        }

        do {
            try Task.checkCancellation()
            let response = try await fetchWeather(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                timeZoneID: request.timeZoneID
            )
            let isDaylight = await sunEventProvider.isDaylight(
                at: request.snapshotDate,
                coordinate: CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude),
                in: timeZone
            )
            try Task.checkCancellation()

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

        guard let timeZone = TimeZone(identifier: timeZoneID) else { throw URLError(.badURL) }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let timestamp = now()
        let key = ResponseKey(url: url, localDay: calendar.startOfDay(for: timestamp))
        try Task.checkCancellation()
        if var cached = responseCache[key], isFresh(cached, at: timestamp) {
            responseAccessOrder &+= 1
            cached.accessOrder = responseAccessOrder
            responseCache[key] = cached
            return cached.response
        }
        responseCache.removeValue(forKey: key)

        let task: Task<OpenMeteoWeatherResponse, Error>
        if let pending = inFlightResponses[key] {
            task = pending
        } else {
            // One caller cancelling must not cancel other callers' shared fetch.
            // The fetch may finish into the cache after dismissal; each caller
            // still checks its own cancellation before using or publishing it.
            task = Task { try await self.downloadResponse(for: key, timeZone: timeZone) }
            inFlightResponses[key] = task
        }
        let response = try await task.value
        try Task.checkCancellation()
        return response
    }

    private func isFresh(_ cached: CachedResponse, at date: Date) -> Bool {
        let age = date.timeIntervalSince(cached.fetchedAt)
        return age >= 0 && age < responseTTL
    }

    private func downloadResponse(for key: ResponseKey, timeZone: TimeZone) async throws -> OpenMeteoWeatherResponse {
        // Only the owning fetch removes its in-flight entry or writes the cache;
        // resumed waiters cannot erase a newer fetch or replace newer data.
        defer { inFlightResponses.removeValue(forKey: key) }
        let request = URLRequest(url: key.url, cachePolicy: .reloadIgnoringLocalCacheData)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(OpenMeteoWeatherResponse.self, from: data)
        guard isValidResponse(decoded, in: timeZone) else { throw URLError(.cannotParseResponse) }
        let timestamp = now()
        responseCache = responseCache.filter { isFresh($0.value, at: timestamp) }
        responseAccessOrder &+= 1
        responseCache[key] = CachedResponse(response: decoded, fetchedAt: timestamp, accessOrder: responseAccessOrder)
        if responseCache.count > responseCapacity,
           let oldest = responseCache.min(by: { $0.value.accessOrder < $1.value.accessOrder })?.key {
            responseCache.removeValue(forKey: oldest)
        }
        return decoded
    }

    private func isValidResponse(_ response: OpenMeteoWeatherResponse, in timeZone: TimeZone) -> Bool {
        func validTemperature(_ value: Double) -> Bool {
            value.isFinite && Int(exactly: value.rounded()) != nil
        }
        guard response.current != nil || response.hourly != nil else { return false }
        if let current = response.current {
            guard validTemperature(current.temperature2m), validTemperature(current.apparentTemperature) else { return false }
        }
        if let hourly = response.hourly {
            let count = hourly.time.count
            guard count > 0, hourly.temperature2m.count == count,
                  hourly.apparentTemperature.count == count, hourly.weatherCode.count == count,
                  hourly.temperature2m.allSatisfy(validTemperature),
                  hourly.apparentTemperature.allSatisfy(validTemperature),
                  // Validate timestamp syntax independently of DST gaps. The
                  // existing selector skips any nonexistent local hour; do not
                  // reject otherwise usable current/hourly data because of it.
                  hourly.time.allSatisfy({ localDate(from: $0, in: TimeZone(secondsFromGMT: 0)!) != nil }),
                  hourly.time.contains(where: { localDate(from: $0, in: timeZone) != nil }) else { return false }
        }
        return true
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

    private struct SolarDayKey: Hashable {
        let latitude: Double
        let longitude: Double
        let timeZoneID: String
        let year: Int
        let month: Int
        let day: Int
    }

    private struct SolarDay {
        let events: SunEvents?
        let continuousDaylight: Bool?
    }

    // Shared by the weather icon and daylight card. These are local calculation
    // results only; no weather responses or additional coordinates are persisted.
    private var solarDayCache: [SolarDayKey: SolarDay] = [:]

    func isDaylight(at date: Date, coordinate: CLLocationCoordinate2D, in timeZone: TimeZone) -> Bool {
        guard date.timeIntervalSinceReferenceDate.isFinite,
              coordinate.latitude.isFinite, coordinate.longitude.isFinite,
              CLLocationCoordinate2DIsValid(coordinate) else { return false }
        // Elevation uses the absolute selected instant, independent of local date/DST.
        // Geometric solar-center elevation: the existing 90.833° zenith includes
        // the solar radius and standard refraction once, through this threshold.
        let elevation = SolarPosition(date: date).elevation(
            latitude: coordinate.latitude, longitude: coordinate.longitude
        )
        return elevation.isFinite && elevation >= -0.833
    }

    private let availabilityWindow: TimeInterval = 10 * 365 * 24 * 60 * 60

    func resolve(for request: SunRequest) async -> DaylightResolution {
        guard abs(request.snapshotDate.timeIntervalSince(request.requestedAt)) <= availabilityWindow else {
            return .distantTime
        }

        guard !Task.isCancelled, !request.isReferenceOffsetCity,
              let point = request.coordinate,
              point.latitude.isFinite, point.longitude.isFinite,
              CLLocationCoordinate2DIsValid(CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)) else {
            return .error
        }

        let coordinate = CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
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

        var candidates = [
            SolarEvent(kind: .sunrise, date: currentDayEvents.sunrise),
            SolarEvent(kind: .sunset, date: currentDayEvents.sunset)
        ]
        // If both remaining events are today, no neighboring calculation is needed.
        if let presentation = nextPresentation(after: request.snapshotDate, candidates: candidates) {
            return .loaded(presentation)
        }

        // Bound the search to today and tomorrow in the city's calendar. Missing
        // polar events remain unavailable; do not search months ahead or invent a pair.
        if let nextLocalDay = calendar.date(byAdding: .day, value: 1,
                                           to: calendar.startOfDay(for: request.snapshotDate)),
           let events = sunEvents(for: nextLocalDay, coordinate: coordinate,
                                  timeZone: request.timeZone, calendar: calendar) {
            candidates.append(SolarEvent(kind: .sunrise, date: events.sunrise))
            candidates.append(SolarEvent(kind: .sunset, date: events.sunset))
        }
        guard let presentation = nextPresentation(after: request.snapshotDate, candidates: candidates) else {
            return .error
        }
        return .loaded(presentation)
    }

    private struct SolarEvent {
        let kind: SunEventKind
        let date: Date
    }

    private func nextPresentation(after instant: Date, candidates: [SolarEvent]) -> SunPresentation? {
        guard instant.timeIntervalSinceReferenceDate.isFinite else { return nil }
        // An event at the selected instant is complete, matching the existing
        // sunrise/sunset boundary behavior. Compare absolute instants, never clock hours.
        let future = candidates.filter {
            $0.date.timeIntervalSinceReferenceDate.isFinite && $0.date > instant
        }.sorted { $0.date < $1.date }
        guard future.count >= 2 else { return nil }
        let primary = future[0], secondary = future[1]
        // Do not skip a contradictory event merely to find an alternating pair.
        // Coincident events (including a third event at the secondary instant)
        // cannot establish a unique chronological pair.
        guard primary.date < secondary.date,
              !future.dropFirst(2).contains(where: { $0.date == secondary.date }) else { return nil }
        switch (primary.kind, secondary.kind) {
        case (.sunrise, .sunset), (.sunset, .sunrise):
            return SunPresentation(primaryKind: primary.kind, primaryDate: primary.date,
                                   secondaryKind: secondary.kind, secondaryDate: secondary.date)
        default:
            return nil
        }
    }

    private func sunEvents(
        for date: Date,
        coordinate: CLLocationCoordinate2D,
        timeZone: TimeZone,
        calendar: Calendar
    ) -> SunEvents? {
        solarDay(for: date, coordinate: coordinate, timeZone: timeZone, calendar: calendar).events
    }

    private func solarDay(
        for date: Date,
        coordinate: CLLocationCoordinate2D,
        timeZone: TimeZone,
        calendar: Calendar
    ) -> SolarDay {
        guard date.timeIntervalSinceReferenceDate.isFinite,
              CLLocationCoordinate2DIsValid(coordinate) else {
            return SolarDay(events: nil, continuousDaylight: nil)
        }
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = components.year, let month = components.month, let day = components.day else {
            return SolarDay(events: nil, continuousDaylight: nil)
        }
        let key = SolarDayKey(latitude: coordinate.latitude, longitude: coordinate.longitude,
                              timeZoneID: timeZone.identifier, year: year, month: month, day: day)
        if let cached = solarDayCache[key] { return cached }

        let events = calculateSunEvents(for: date, coordinate: coordinate, timeZone: timeZone, calendar: calendar)
        var continuousDaylight: Bool?
        if events == nil || events?.sunrise == events?.sunset {
            let century = julianCentury(from: julianDay(year: year, month: month, day: day))
            let cosine = cosineHourAngleSunrise(latitude: coordinate.latitude,
                                                 solarDeclination: solarDeclination(for: century))
            if cosine.isFinite {
                if cosine <= -1 { continuousDaylight = true }
                if cosine >= 1 { continuousDaylight = false }
            }
        }
        let result = SolarDay(events: events, continuousDaylight: continuousDaylight)
        if solarDayCache.count >= 16 { solarDayCache.removeAll(keepingCapacity: true) }
        solarDayCache[key] = result
        return result
    }

    private func calculateSunEvents(
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

        guard let sunrise = solarEventDate(
            year: year,
            month: month,
            day: day,
            coordinate: coordinate,
            timeZone: timeZone,
            calendar: calendar,
            isSunrise: true
        ),
        let sunset = solarEventDate(
            year: year,
            month: month,
            day: day,
            coordinate: coordinate,
            timeZone: timeZone,
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
        let utcMinutes = 720 - 4 * (coordinate.longitude + signedHourAngle) - equationOfTime

        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
        guard let utcMidnight = utcCalendar.date(from: DateComponents(
            year: year,
            month: month,
            day: day
        )), let localDay = calendar.date(from: DateComponents(
            timeZone: timeZone,
            year: year,
            month: month,
            day: day
        )) else {
            return nil
        }

        // The astronomical result is UTC minutes, not elapsed time from local
        // midnight: a local day can contain a DST transition. Near the date line,
        // the event's UTC date can also differ from its selected local date.
        let event = utcMidnight.addingTimeInterval(utcMinutes * 60)
        for dayOffset in [0, -1, 1] {
            if let candidate = utcCalendar.date(byAdding: .day, value: dayOffset, to: event),
               calendar.isDate(candidate, inSameDayAs: localDay) {
                return candidate
            }
        }
        return nil
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
        let cosineHourAngle = cosineHourAngleSunrise(latitude: latitude, solarDeclination: solarDeclination)
        guard cosineHourAngle >= -1.0, cosineHourAngle <= 1.0 else {
            return nil
        }

        return radiansToDegrees(acos(cosineHourAngle))
    }

    private func cosineHourAngleSunrise(latitude: Double, solarDeclination: Double) -> Double {
        let latitudeRadians = degreesToRadians(latitude)
        let declinationRadians = degreesToRadians(solarDeclination)
        let zenithRadians = degreesToRadians(90.833)

        return (
            cos(zenithRadians) / (cos(latitudeRadians) * cos(declinationRadians))
        ) - tan(latitudeRadians) * tan(declinationRadians)

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

private struct EventEditView: UIViewControllerRepresentable {
    let eventStore: EKEventStore
    let date: Date
    let timeZone: TimeZone
    let notes: String

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let controller = EKEventEditViewController()
        controller.eventStore = eventStore

        let event = EKEvent(eventStore: eventStore)
        event.startDate = date
        event.endDate = date.addingTimeInterval(60 * 60)
        event.timeZone = timeZone
        if let defaultCalendar = eventStore.defaultCalendarForNewEvents {
            event.calendar = defaultCalendar
        }
        event.notes = notes

        controller.event = event
        controller.editViewDelegate = context.coordinator

        return controller
    }

    func updateUIViewController(_ uiViewController: EKEventEditViewController, context: Context) {
        // No-op
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, EKEventEditViewDelegate {
        func eventEditViewController(
            _ controller: EKEventEditViewController,
            didCompleteWith action: EKEventEditViewAction
        ) {
            controller.dismiss(animated: true)
        }
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

// Uses the existing footer's typography and padding; only its content adapts.
private struct CityDetailsFooter: View {
    @Environment(\.appTheme) private var theme
    @ScaledMetric(relativeTo: .subheadline) private var footerFontSize = 14.0

    let timeZoneDisplayText: String
    let shouldShowDSTTag: Bool
    let cityViewPreference: CityViewPreference

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                weatherAttribution.fixedSize()
                Spacer(minLength: 0)
                footerTimeZone.fixedSize()
            }

            VStack(alignment: .leading, spacing: 8) {
                weatherAttribution
                footerTimeZone
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .font(.system(size: footerFontSize, weight: .regular))
        .tracking(-0.42)
        .foregroundStyle(theme.textSecondary)
        .frame(maxWidth: .infinity)
    }

    private var weatherAttribution: some View {
        Link("Data by Open-Meteo.com", destination: URL(string: "https://open-meteo.com/")!)
            .buttonStyle(.plain)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("cityDetails.weatherAttribution")
    }

    private var footerTimeZone: some View {
        HStack(spacing: 4) {
            Image(systemName: "globe.europe.africa.fill")
                .accessibilityHidden(true)

            Text(timeZoneDisplayText)
                .fixedSize(horizontal: false, vertical: true)

            if shouldShowDSTTag {
                DSTBadgeView(cityViewPreference: cityViewPreference)
            }
        }
        .accessibilityIdentifier("cityDetails.timeZone")
    }

}

/// A sheet's own bounds can be portrait even on the open landscape display.
/// Read its window instead, requiring a live fully-open hinge and the whole
/// display so Split View never receives the wider text composition.
private struct CityDetailsLayoutObserver: UIViewRepresentable {
    struct Configuration: Equatable {
        var usesWideSummary = false
        var usesTwentyPointFooterSpacing = false
        var expandsContentSafeArea = false
        var isInnerSplitView = false
        var summaryVerticalOffset: CGFloat = 0
    }

    var changed: (Configuration) -> Void

    static func configuration(hinge: DuoHingeState.Status, window: CGSize, screen: CGSize) -> Configuration {
        let isInnerSplitView = (hinge == .fullyOpen || hinge == .partiallyOpen) &&
            window.width < screen.width - 1 && abs(window.height - screen.height) < 1
        return Configuration(
            usesWideSummary: usesWideSummary(hinge: hinge, window: window, screen: screen),
            usesTwentyPointFooterSpacing: hinge == .closed ||
                (hinge != .unavailable && screen.width > screen.height),
            expandsContentSafeArea: hinge == .closed || isInnerSplitView,
            isInnerSplitView: isInnerSplitView,
            summaryVerticalOffset: hinge == .closed ||
                (hinge != .unavailable && screen.width > screen.height) ? 20 : 0)
    }

    static func usesWideSummary(hinge: DuoHingeState.Status, window: CGSize, screen: CGSize) -> Bool {
        hinge == .fullyOpen && window.width > window.height &&
            abs(window.width - screen.width) < 1 && abs(window.height - screen.height) < 1
    }

    func makeUIView(context: Context) -> ObserverView {
        let view = ObserverView()
        view.changed = changed
        if #available(iOS 27.1, *) {
            view.addInteraction(UIHingeInteraction { [weak view] _, context in
                switch context.hinge?.status {
                case .fullyOpen: view?.hinge = .fullyOpen
                case .partiallyOpen: view?.hinge = .partiallyOpen
                case .closed: view?.hinge = .closed
                default: view?.hinge = .unavailable
                }
                view?.scheduleUpdate()
            })
        }
        return view
    }

    func updateUIView(_ view: ObserverView, context: Context) {
        view.changed = changed
        view.scheduleUpdate()
    }

    final class ObserverView: UIView {
        var changed: ((Configuration) -> Void)?
        var hinge: DuoHingeState.Status = .unavailable
        private var lastValue: Configuration?
        private var updatePending = false

        override func didMoveToWindow() {
            super.didMoveToWindow()
            scheduleUpdate()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            scheduleUpdate()
        }

        func scheduleUpdate() {
            guard !updatePending else { return }
            updatePending = true
            // Deliver after SwiftUI's current layout/update, using the latest
            // geometry and hinge state if several changes arrived together.
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                updatePending = false
                guard let window, let scene = window.windowScene else { return }
                let value = CityDetailsLayoutObserver.configuration(
                    hinge: hinge, window: window.bounds.size, screen: scene.screen.bounds.size)
                guard value != lastValue else { return }
                lastValue = value
                changed?(value)
            }
        }
    }
}

/// Keep left Split View actions in the top bar. The status-bearing right
/// pane needs automatic placement to avoid reserving an extra top gutter.
private struct CityDetailsToolbarPlacement: ViewModifier {
    let keepsTopCorners: Bool

    func body(content: Content) -> some View {
        if #available(iOS 27.1, *) {
            content.toolbarVerticalBehavior(keepsTopCorners ? .disabled : .automatic)
        } else {
            content
        }
    }
}

/// Use the presenting window's rail side. Reading toolbarVerticalEdge here
/// would feed the result of our toolbar override back into its own placement.
private struct CityDetailsContentSafeArea: ViewModifier {
    @Environment(\.layoutDirection) private var layoutDirection
    let enabled: Bool
    var railOnRight = true

    func body(content: Content) -> some View {
        let trailing = railOnRight == (layoutDirection == .leftToRight)
        content.ignoresSafeArea(.container, edges: enabled ? (trailing ? .trailing : .leading) : [])
    }
}

/// GeometryReader ends at the safe-area boundary; the visible sheet continues
/// below it. Keep the summary's original allocation while changing only the
/// space occupied by the cards and footer.
private struct CityDetailsFooterSpacing {
    let top: CGFloat
    let bottom: CGFloat
    let summaryBottom: CGFloat

    init(usesTwentyPointGaps: Bool, safeAreaBottom: CGFloat) {
        top = usesTwentyPointGaps ? 20 : 32
        bottom = usesTwentyPointGaps ? 20 - safeAreaBottom : safeAreaBottom - 32
        summaryBottom = usesTwentyPointGaps ? 2 * safeAreaBottom - 40 : 0
    }
}
