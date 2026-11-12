import Foundation
import Combine
import CoreLocation
import MapKit

@MainActor
final class CurrentLocationCityProvider: NSObject, ObservableObject {
    enum PermissionState {
        case notDetermined
        case authorized
        case denied
    }

    @Published private(set) var currentCityItem: CitySearchItem?
    @Published private(set) var permissionState: PermissionState = .notDetermined
    @Published private(set) var isResolvingCurrentCity = false

    private let locationManager = CLLocationManager()
    private var hasRequestedAuthorization = false
    private var isRequestingLocation = false
    private var reverseGeocodingRequest: MKReverseGeocodingRequest?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        permissionState = Self.permissionState(from: locationManager.authorizationStatus)
    }

    func requestCurrentCity() {
        permissionState = Self.permissionState(from: locationManager.authorizationStatus)

        switch locationManager.authorizationStatus {
        case .notDetermined:
            isResolvingCurrentCity = false
            guard !hasRequestedAuthorization else { return }
            hasRequestedAuthorization = true
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            requestOneShotLocation()
        case .denied, .restricted:
            isResolvingCurrentCity = false
            currentCityItem = nil
        @unknown default:
            isResolvingCurrentCity = false
            currentCityItem = nil
        }
    }

    private static func permissionState(from status: CLAuthorizationStatus) -> PermissionState {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            return .authorized
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }

    private func requestOneShotLocation() {
        guard !isRequestingLocation else { return }
        isRequestingLocation = true
        isResolvingCurrentCity = true
        locationManager.requestLocation()
    }

    private func reverseGeocode(_ location: CLLocation) {
        reverseGeocodingRequest?.cancel()

        guard let request = MKReverseGeocodingRequest(location: location) else {
            isRequestingLocation = false
            isResolvingCurrentCity = false
            currentCityItem = nil
            return
        }

        request.preferredLocale = Locale(identifier: "en_US_POSIX")
        reverseGeocodingRequest = request

        Task { [weak self] in
            guard let self else { return }

            do {
                let mapItems = try await request.mapItems
                guard !Task.isCancelled else { return }
                guard self.reverseGeocodingRequest === request else { return }

                self.reverseGeocodingRequest = nil
                self.isRequestingLocation = false
                self.isResolvingCurrentCity = false

                guard
                    let mapItem = mapItems.first,
                    let normalizedCity = Self.normalizedCityName(from: mapItem),
                    let country = Self.countryName(from: mapItem)
                else {
                    self.currentCityItem = nil
                    return
                }

                self.currentCityItem = Self.cityItem(
                    city: normalizedCity,
                    country: country,
                    timeZoneIdentifier: (mapItem.timeZone ?? TimeZone.current).identifier,
                    resolvedCoordinate: mapItem.location.coordinate,
                    deviceCoordinate: location.coordinate
                )
            } catch {
                guard !Task.isCancelled else { return }
                guard self.reverseGeocodingRequest === request else { return }

                self.reverseGeocodingRequest = nil
                self.isRequestingLocation = false
                self.isResolvingCurrentCity = false
                self.currentCityItem = nil
            }
        }
    }

    private static func cityItem(
        city: String,
        country: String,
        timeZoneIdentifier: String,
        resolvedCoordinate: CLLocationCoordinate2D,
        deviceCoordinate: CLLocationCoordinate2D
    ) -> CitySearchItem {
        // Catalog matches retain their existing settlement coordinates and identity.
        if let canonical = CitySearchProvider.shared.canonicalItemForCurrentLocation(
            city: city, country: country, timeZoneIdentifier: timeZoneIdentifier
        ) {
            return canonical
        }

        // Keep geography from the completed request. The device fix is only a
        // fallback for this location-derived place, never for manual selections.
        let coordinate = [resolvedCoordinate, deviceCoordinate].first {
            $0.latitude.isFinite && $0.longitude.isFinite && CLLocationCoordinate2DIsValid($0)
        }
        return CitySearchItem(
            id: "current-location-\(Self.normalize(city))|\(Self.normalize(country))|\(timeZoneIdentifier)",
            city: city,
            country: country,
            timeZoneIdentifier: timeZoneIdentifier,
            aliases: [],
            geographicalEvidence: .init(
                placeIdentifier: nil, alternatePlaceIdentifiers: nil,
                originalName: nil, cityName: city, countryCode: nil,
                coordinates: coordinate.map { .init(latitude: $0.latitude, longitude: $0.longitude) },
                cityWithContext: nil, cityWithFullContext: nil,
                fullAddress: nil, shortAddress: nil, pointOfInterestCategory: nil
            )
        )
    }

    private static func normalizedCityName(from mapItem: MKMapItem) -> String? {
        let locality = mapItem.addressRepresentations?.cityName
        let subAdministrativeArea = firstAddressComponent(from: mapItem.addressRepresentations?.cityWithContext)
        let administrativeArea = secondAddressComponent(from: mapItem.addressRepresentations?.cityWithContext(.full))

        return firstNonEmpty([locality, subAdministrativeArea, administrativeArea])
    }

    private static func countryName(from mapItem: MKMapItem) -> String? {
        firstNonEmpty([
            mapItem.addressRepresentations?.regionName,
            lastAddressComponent(from: mapItem.addressRepresentations?.cityWithContext(.full)),
            lastAddressComponent(from: mapItem.address?.fullAddress)
        ])
    }

    private static func firstAddressComponent(from value: String?) -> String? {
        guard let value else { return nil }

        return value
            .replacingOccurrences(of: "\n", with: ",")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first(where: { !$0.isEmpty })
    }

    private static func lastAddressComponent(from value: String?) -> String? {
        guard let value else { return nil }

        return value
            .replacingOccurrences(of: "\n", with: ",")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .last(where: { !$0.isEmpty })
    }

    private static func secondAddressComponent(from value: String?) -> String? {
        guard let value else { return nil }

        let components = value
            .replacingOccurrences(of: "\n", with: ",")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard components.count >= 2 else {
            return nil
        }

        return components[1]
    }

    private static func firstNonEmpty(_ values: [String?]) -> String? {
        for value in values {
            let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !trimmed.isEmpty else { continue }
            if trimmed.contains(where: { $0.isNumber }) { continue }
            return trimmed
        }
        return nil
    }

    private static func normalize(_ input: String) -> String {
        input
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}

extension CurrentLocationCityProvider: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor [weak self] in
            self?.requestCurrentCity()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            Task { @MainActor [weak self] in
                self?.isRequestingLocation = false
                self?.isResolvingCurrentCity = false
            }
            return
        }

        Task { @MainActor [weak self] in
            self?.reverseGeocode(location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            self?.isRequestingLocation = false
            self?.isResolvingCurrentCity = false
            self?.currentCityItem = nil
        }
    }
}
