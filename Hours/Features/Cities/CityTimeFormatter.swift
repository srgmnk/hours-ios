import Foundation

enum CityTimeFormatter {
    struct TimeComponents {
        let numeric: String
        let meridiem: String?
    }

    private static let timeFormatter: DateFormatter = {
        DateFormatter()
    }()

    private static let meridiemFormatter: DateFormatter = {
        DateFormatter()
    }()

    private static let dateFormatter: DateFormatter = {
        DateFormatter()
    }()


    static func formatTime(_ instant: Date, in timeZone: TimeZone) -> String {
        let components = formatTimeComponents(instant, in: timeZone)
        if let meridiem = components.meridiem {
            return "\(components.numeric) \(meridiem)"
        }
        return components.numeric
    }

    static func formatTimeComponents(_ instant: Date, in timeZone: TimeZone) -> TimeComponents {
        let locale = Locale.autoupdatingCurrent
        let uses12HourClock = resolvedUses12HourClock(for: locale)
        let resolvedFormat = uses12HourClock ? "hh:mm" : "HH:mm"

        timeFormatter.locale = locale
        timeFormatter.dateFormat = resolvedFormat
        timeFormatter.timeZone = timeZone
        let numeric = timeFormatter.string(from: instant)

        guard uses12HourClock else {
            return TimeComponents(numeric: numeric, meridiem: nil)
        }

        meridiemFormatter.locale = locale
        meridiemFormatter.dateFormat = "a"
        meridiemFormatter.timeZone = timeZone
        let meridiem = meridiemFormatter.string(from: instant).uppercased(with: locale)
        return TimeComponents(numeric: numeric, meridiem: meridiem)
    }

    static func formatDate(_ instant: Date, in timeZone: TimeZone,
                           locale: Locale = CityTimeFormatter.deviceDateLocale()) -> String {
        // Read device language/region preferences on each render, even when the
        // app's UI falls back to English. The calendar date still belongs to the city.
        dateFormatter.locale = locale
        dateFormatter.calendar = locale.calendar
        dateFormatter.timeZone = timeZone
        dateFormatter.setLocalizedDateFormatFromTemplate("EEEdMMM")
        return dateFormatter.string(from: instant)
    }

    static func deviceDateLocale(regionLocale: Locale = .autoupdatingCurrent,
                                 preferredLocale: Locale? = Locale.preferredLocales.first) -> Locale {
        guard let preferredLocale else { return regionLocale }
        var components = Locale.Components(locale: regionLocale)
        // Change only the language/script: a preferred language can carry a
        // different region, and must not replace the device's regional choices.
        components.languageComponents.languageCode = preferredLocale.language.languageCode
        components.languageComponents.script = preferredLocale.language.script
        components.calendar = regionLocale.calendar.identifier
        return Locale(components: components)
    }


    static func formatUTCOffset(_ instant: Date, in timeZone: TimeZone) -> String {
        let seconds = timeZone.secondsFromGMT(for: instant)
        let sign = seconds >= 0 ? "+" : "−"
        let totalMinutes = abs(seconds / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if minutes == 0 {
            return "UTC\(sign)\(hours)"
        }
        return String(format: "UTC%@%d:%02d", sign, hours, minutes)
    }

    static func formatUTCOffsetValue(_ instant: Date, in timeZone: TimeZone) -> String {
        let full = formatUTCOffset(instant, in: timeZone)
        return full.replacingOccurrences(of: "UTC", with: "")
    }

    private static func uses12HourClock(for locale: Locale) -> Bool {
        let hourTemplate = DateFormatter.dateFormat(
            fromTemplate: "j",
            options: 0,
            locale: locale
        ) ?? ""
        return hourTemplate.contains("a")
    }

    private static func resolvedUses12HourClock(for locale: Locale) -> Bool {
        let systemUses12HourClock = uses12HourClock(for: locale)
        let rawPreference = UserDefaults.standard.string(forKey: AppTimeFormatPreference.storageKey) ?? AppTimeFormatPreference.system.rawValue
        let preference = AppTimeFormatPreference.from(rawValue: rawPreference)
        return preference.resolvedUses12HourClock(systemUses12HourClock: systemUses12HourClock)
    }
}
