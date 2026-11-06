import SwiftUI

/// Future map presentation boundary. Pass TimeDialScreen's existing model and
/// app-provided store; this view observes them without creating or owning either.
/// Instantiate only in the active map branch, below the geometry boundary.
/// Keeping it unmounted in List mode avoids image decoding and marker creation.
struct WorldMapObservedContent: View {
    @ObservedObject var viewModel: TimeDialViewModel
    @ObservedObject var cityStore: CityStore
    let viewportSize: CGSize
    @Binding var horizontalPosition: CGFloat
    var geometryProfile: WorldMapGeometryProfile = .conventional
    var isPresentationVisible: Bool = true
    var visualViewport: CGRect? = nil
    var usesDuoDrawingContainer: Bool = false
    var onCitySelected: (City.ID) -> Void = { _ in }
    var body: some View {
        // Read both sources here, rather than capturing snapshots in a deferred
        // GeometryReader closure. selectedInstant is the city list's same source.
        WorldMapView(
            viewportSize: viewportSize,
            horizontalPosition: $horizontalPosition,
            cities: cityStore.cities,
            selectedInstant: viewModel.selectedInstant,
            geometryProfile: geometryProfile,
            isPresentationVisible: isPresentationVisible,
            visualViewport: visualViewport,
            usesDuoDrawingContainer: usesDuoDrawingContainer,
            onCitiesSelected: { ids in
                if let id = ids.first { onCitySelected(id) }
            }
        )
    }
}

/// The saved model has no country/region fields. Use only its existing name,
/// time zone and coordinates when duplicate display names need disambiguation.
enum WorldMapCitySelection {
    static func title(for city: City, among cities: [City]) -> String {
        let duplicates = cities.filter { $0.displayName == city.displayName }
        guard duplicates.count > 1 else { return city.displayName }
        var title = city.displayName
        if city.name != city.displayName { title += " — " + city.name }
        title += " — " + city.timeZoneID
        if duplicates.contains(where: { $0.id != city.id && $0.name == city.name && $0.timeZoneID == city.timeZoneID }),
           let latitude = city.latitude, let longitude = city.longitude {
            title += " (\(latitude), \(longitude))"
        }
        return title
    }
}
