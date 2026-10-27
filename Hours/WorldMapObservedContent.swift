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

    var body: some View {
        // Read both sources here, rather than capturing snapshots in a deferred
        // GeometryReader closure. selectedInstant is the city list's same source.
        WorldMapView(
            viewportSize: viewportSize,
            horizontalPosition: $horizontalPosition,
            cities: cityStore.cities,
            selectedInstant: viewModel.selectedInstant
        )
    }
}
