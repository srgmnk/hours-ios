import Foundation

/// Geocentric apparent Sun, geometric elevation (no atmospheric refraction).
/// NOAA's Julian-century / Meeus approximation: https://gml.noaa.gov/grad/solcalc/main.js
/// Date is an absolute UTC instant. Best-supported domain: 1800...2100.
/// UTC approximates UT1 and TT here; this is a global illumination model, not navigation.
nonisolated struct SolarPosition: Equatable {
    let declination: Double
    let subsolarLongitude: Double
    let equationOfTimeMinutes: Double
    var subsolarLatitude: Double { declination }
    static let radians = Double.pi / 180

    init(date: Date) {
        let seconds = date.timeIntervalSince1970
        precondition(seconds.isFinite, "A finite absolute Date is required")
        let t = (2440587.5 + seconds / 86400 - 2451545) / 36525
        let l = Self.wrap(280.46646 + t * (36000.76983 + t * 0.0003032), period: 360) * Self.radians
        let m = (357.52911 + t * (35999.05029 - 0.0001537 * t)) * Self.radians
        let e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t)
        let c = sin(m) * (1.914602 - t * (0.004817 + 0.000014 * t))
            + sin(2 * m) * (0.019993 - 0.000101 * t) + sin(3 * m) * 0.000289
        let omega = (125.04 - 1934.136 * t) * Self.radians
        let lambda = l + (c - 0.00569 - 0.00478 * sin(omega)) * Self.radians
        let epsilon = (23 + (26 + (21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))) / 60) / 60
                       + 0.00256 * cos(omega)) * Self.radians
        declination = asin(sin(epsilon) * sin(lambda)) / Self.radians
        let y = pow(tan(epsilon / 2), 2)
        equationOfTimeMinutes = 4 / Self.radians * (y * sin(2 * l) - 2 * e * sin(m)
            + 4 * e * y * sin(m) * cos(2 * l) - 0.5 * y * y * sin(4 * l) - 1.25 * e * e * sin(2 * m))
        let utcMinutes = Self.wrap(seconds, period: 86400) / 60
        subsolarLongitude = Self.wrap(360 - utcMinutes / 4 - equationOfTimeMinutes / 4, period: 360) - 180
    }

    var direction: SIMD3<Double> {
        let d = declination * Self.radians, l = subsolarLongitude * Self.radians
        return SIMD3(cos(d) * cos(l), cos(d) * sin(l), sin(d))
    }

    func elevation(latitude: Double, longitude: Double) -> Double {
        let p = latitude * Self.radians
        let h = (Self.wrap(longitude + 180, period: 360) - 180 - subsolarLongitude) * Self.radians
        let d = declination * Self.radians
        return asin(min(1, max(-1, sin(p) * sin(d) + cos(p) * cos(d) * cos(h)))) / Self.radians
    }

    static func wrap(_ value: Double, period: Double) -> Double {
        let r = value.truncatingRemainder(dividingBy: period)
        return r < 0 ? r + period : r
    }

    static func latitude(normalizedY: Double) -> Double {
        atan(sinh(.pi * (1 - 2 * normalizedY))) / radians
    }
}

struct NightStyle: Equatable {
    var maximumOpacity: Double = 0.35
    var twilightDegrees: Double = 12
    func opacity(elevation: Double) -> Double {
        let t = min(1, max(0, -elevation / max(0.001, twilightDegrees)))
        return min(1, max(0, maximumOpacity)) * t * t * (3 - 2 * t)
    }
}
