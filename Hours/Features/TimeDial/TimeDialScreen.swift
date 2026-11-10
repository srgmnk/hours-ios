import SwiftUI
import UIKit
import Combine

struct TimeDialScreen: View {
    private enum CityPresentation {
        case list, map
    }

    private enum PersistenceAlertStatus: Equatable {
        case loading, loaded, fileAbsent, loadFailed, unavailable, saveFailed
    }

    private enum PresentedSheet: Hashable {
        case addCity, settings, rename, cityDetails
    }

    private struct CityDetailsPresentation: Identifiable {
        let id = UUID()
        let city: City
        let primaryCity: City
        let date: Date
        let relativeOffsetMinutes: Int
        let cityViewPreference: CityViewPreference
    }

    @StateObject private var viewModel = TimeDialViewModel()
    @StateObject private var currentLocationProvider = CurrentLocationCityProvider()
    @EnvironmentObject private var cityStore: CityStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var lastSnappedOffsetSteps = 0
    @State private var isDraggingSessionActive = false
    @State private var dialHeight: CGFloat = 260
    @State private var isAddCitySheetPresented = false
    @State private var isSettingsSheetPresented = false
    @State private var cityBeingRenamed: City?
    @State private var cityDetailsPresentation: CityDetailsPresentation?
    @State private var pendingAddedCityItem: CitySearchItem?
    @State private var isPersistenceAlertPresented = false
    @State private var hasAcknowledgedPersistenceFailure = false
    @State private var sheetsAwaitingDismissal: Set<PresentedSheet> = []
    @State private var cityPresentation: CityPresentation = .list
    @State private var mapHorizontalPosition = WorldMapView.initialHorizontalPosition
    @State private var duoHinge = DuoHingeState()
    @State private var usesCompactSettingsHeader = false
    @State private var duoMapMounted = false
    @State private var mapHasBeenPresented = false
    @AppStorage(OnboardingStorageKey.hasCompleted) private var hasCompletedOnboarding = false
    @AppStorage(CityViewPreference.storageKey) private var cityViewPreferenceRawValue = CityViewPreference.basic.rawValue
    @StateObject private var emptyStateQuoteProvider = EmptyStateQuoteProvider()

    private let dialSize: CGFloat = 512
    private let dialCenterYOffset: CGFloat = 125
    private let dialOverlayHeight: CGFloat = 260
    private let cityListDesiredBottomGap: CGFloat = 130
    private let topButtonTopOffset: CGFloat = 60
    private let topButtonBarHeight: CGFloat = 48
    private let topButtonBarTopPadding: CGFloat = 1
    private let logoHeight: CGFloat = 15
    private let logoWidth: CGFloat = 49
    private let smallTickHaptics = UIImpactFeedbackGenerator(style: .light)
    private let bigTickHaptics = UIImpactFeedbackGenerator(style: .heavy)
    private let zeroTickHaptics = UINotificationFeedbackGenerator()
    private let resetNotificationHaptics = UINotificationFeedbackGenerator()

    private var hapticsEnabled: Bool {
        #if targetEnvironment(simulator)
        false
        #else
        true
        #endif
    }

    private var selectedCityViewPreference: CityViewPreference {
        CityViewPreference.from(rawValue: cityViewPreferenceRawValue)
    }

    var body: some View {
        Group {
            if #available(iOS 27.1, *), duoHinge.isConfirmed {
                duoPresentation
            } else {
                conventionalPresentation
            }
        }
        .background {
            DuoHingeObserver { status in duoHinge.receive(status) }
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .sheet(isPresented: $isAddCitySheetPresented, onDismiss: {
            if let pendingItem = pendingAddedCityItem {
                pendingAddedCityItem = nil
                DispatchQueue.main.async {
                    appendCityIfNeeded(pendingItem)
                }
            }
            currentLocationProvider.requestCurrentCity()
            persistenceSheetDidDismiss(.addCity)
        }) {
            AddCitySheetView(
                existingCanonicalIDs: Set(cityStore.cities.map(\.id))
            ) { selectedItem in
                pendingAddedCityItem = selectedItem
            }
        }
        .sheet(isPresented: $isSettingsSheetPresented, onDismiss: {
            persistenceSheetDidDismiss(.settings)
        }) { [usesCompactSettingsHeader] in
            SettingsSheetView(usesCompactHeader: usesCompactSettingsHeader)
        }
        .sheet(item: $cityBeingRenamed, onDismiss: {
            persistenceSheetDidDismiss(.rename)
        }) { city in
            ChangeCityNameSheetView(city: city) { customName in
                applyCustomDisplayName(customName, toCityID: city.id)
            }
        }
        .sheet(item: $cityDetailsPresentation, onDismiss: {
            persistenceSheetDidDismiss(.cityDetails)
        }) { presentation in
            CityDetailsView(
                city: presentation.city,
                primaryCity: presentation.primaryCity,
                date: presentation.date,
                relativeOffsetMinutes: presentation.relativeOffsetMinutes,
                cityViewPreference: presentation.cityViewPreference
            )
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(38)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                currentLocationProvider.requestCurrentCity()
                updatePersistenceAlert()
            }
        }
        .onChange(of: persistenceAlertStatus, initial: true) { _, _ in
            updatePersistenceAlert()
        }
        .onChange(of: hasCompletedOnboarding) { _, _ in
            updatePersistenceAlert()
        }
        .alert("Unable to Save Changes", isPresented: $isPersistenceAlertPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("City changes cannot be saved right now. Changes made in the app may be lost when you close it.")
        }
    }

    // Keep this production branch's layout and modifier order unchanged.
    private var conventionalPresentation: some View {
        GeometryReader { container in
        GeometryReader { geo in
            let topSafeInset = resolvedTopSafeAreaInset(from: geo)
            let topControlsTop = max(
                topButtonTopOffset - max(0, 59 - container.safeAreaInsets.top),
                container.safeAreaInsets.top + topButtonBarTopPadding
            )
            let isCitiesEmpty = cityStore.cities.isEmpty
            let sharedLogoTopInset = topSafeInset + topButtonBarTopPadding + ((topButtonBarHeight - logoHeight) / 2)

            TimeDialObservedContent(viewModel: viewModel) { selectedInstant, rotationDegrees, dialSteps, resetSignal, mode, deltaText in
                ZStack(alignment: .bottom) {
                    AppScreenBackground()
                        .ignoresSafeArea()

                    CityPresentationContent(presentation: $cityPresentation, isCitiesEmpty: isCitiesEmpty) {
                        if isCitiesEmpty {
                            ZStack(alignment: .top) {
                                MainEmptyStateQuoteView(quote: emptyStateQuoteProvider.currentQuote)
                                    .frame(width: geo.size.width, height: geo.size.height, alignment: .center)

                                Image("HoursLogo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: logoWidth, height: logoHeight)
                                    .padding(.top, sharedLogoTopInset)
                            }
                            .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
                            .allowsHitTesting(false)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    emptyStateQuoteProvider.randomizeQuote()
                                }
                            }
                            .overlay {
                                ShakeDetectorView {
                                    changeQuote()
                                }
                                .allowsHitTesting(false)
                            }
                        } else {
                            CityListStoreObservation(cityStore: cityStore) { cities in
                                CityListReorderUIKitView(
                                    cities: cities,
                                    selectedInstant: selectedInstant,
                                    userCurrentLocationItem: currentLocationProvider.currentCityItem,
                                    // Keep scroll content layout independent from pinned button offset.
                                    topSafeAreaInset: topButtonBarTopPadding + ((topButtonBarHeight - logoHeight) / 2),
                                    // Desired visual stop gap from physical screen bottom.
                                    bottomContentInset: cityListDesiredBottomGap,
                                    onRenameRequested: presentRenameSheet(for:),
                                    onCitySelected: presentCityDetails(for:)
                                )
                            }
                            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                        }
                    } map: {
                        WorldMapObservedContent(
                            viewModel: viewModel,
                            cityStore: cityStore,
                            viewportSize: geo.size,
                            horizontalPosition: $mapHorizontalPosition,
                            onCitySelected: presentMapCityDetails(for:)
                        )
                        .onAppear { mapHasBeenPresented = true }
                        .overlay(alignment: .top) {
                            Image("HoursLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: logoWidth, height: logoHeight)
                                .padding(.top, sharedLogoTopInset)
                                .allowsHitTesting(false)
                        }
                    }
                    .id(isCitiesEmpty ? "empty" : "list")

                    ProgressiveBottomBlurOverlay(height: 180)
                        .allowsHitTesting(false)

                    dialOverlay(
                        in: geo,
                        rotationDegrees: rotationDegrees,
                        stepIndex: dialSteps,
                        resetSignal: resetSignal,
                        mode: mode,
                        deltaText: deltaText
                    )
                        // Measure the rendered dial overlay height and feed it into list bottom padding.
                        .background(
                            GeometryReader { proxy in
                                Color.clear
                                    .preference(key: DialOverlayHeightPreferenceKey.self, value: proxy.size.height)
                            }
                        )

                }
                .overlay(alignment: .bottomLeading) {
                    CityPresentationSwitcher(
                        presentation: $cityPresentation,
                        selectedInstant: selectedInstant,
                        cityStore: cityStore
                    )
                        .padding(.leading, container.safeAreaInsets.leading + 24)
                        .padding(.bottom, 24)
                }
                .overlay(alignment: .top) {
                    let horizontalControls = topButtonBar()
                        .padding(.leading, container.safeAreaInsets.leading)
                        .padding(.trailing, container.safeAreaInsets.trailing)
                        .padding(.top, topControlsTop)
                    Group {
                        if #available(iOS 27.1, *) {
                            TrailingRegionControls(
                                geometry: geo,
                                contentFrame: container.frame(in: .global),
                                wheelFrame: CGRect(
                                    x: (geo.size.width - dialSize) / 2,
                                    y: geo.size.height - 2 * geo.safeAreaInsets.bottom + dialCenterYOffset - dialSize / 2,
                                    width: dialSize, height: dialSize
                                ),
                                horizontal: horizontalControls,
                                settings: settingsButton(),
                                add: addButton(iconOnly: true)
                            )
                        } else {
                            horizontalControls
                        }
                    }
                    .ignoresSafeArea(edges: .top)
                    .zIndex(10)
                }
                .onPreferenceChange(DialOverlayHeightPreferenceKey.self) { measuredHeight in
                    guard measuredHeight > 0 else { return }
                    dialHeight = measuredHeight
                }
                .onAppear {
                    prepareDialHaptics()
                    resetNotificationHaptics.prepare()
                    lastSnappedOffsetSteps = viewModel.dialSteps
                    currentLocationProvider.requestCurrentCity()
                }
                .onChange(of: dialSteps) { _, newStep in
                    guard newStep != lastSnappedOffsetSteps else { return }
                    let tickType: String
                    if newStep == 0 {
                        tickType = "zero"
                    } else if abs(newStep).isMultiple(of: 12) {
                        tickType = "big"
                    } else {
                        tickType = "small"
                    }
                    log(
                        "[DIAL] snappedStep \(lastSnappedOffsetSteps) -> \(newStep) " +
                        "kind=\(tickType)"
                    )
                    fireHapticForSnappedStep(newStep)
                    lastSnappedOffsetSteps = newStep
                }
            }
        }
        // Keep the mounted map and dial alive across appearance changes.
        .id(cityStore.cities.isEmpty ? "empty" : "list")
        .ignoresSafeArea()
        }
    }

    @available(iOS 27.1, *)
    private var duoPresentation: some View {
        DuoLayoutContainer(hinge: duoHinge) { layout, geometry in
            TimeDialObservedContent(viewModel: viewModel) { instant, rotation, steps, reset, mode, delta in
                let mapVisible = layout.isInner || cityPresentation == .map
                let listVisible = layout.isInner || cityPresentation == .list
                ZStack(alignment: .topLeading) {
                    AppScreenBackground()
                    // Retain the native map and its renderer after the first use.
                    if mapVisible || duoMapMounted {
                        WorldMapObservedContent(
                            viewModel: viewModel, cityStore: cityStore,
                            viewportSize: layout.mapRenderingViewport.size, horizontalPosition: $mapHorizontalPosition,
                            geometryProfile: layout.mapGeometryProfile,
                            isPresentationVisible: mapVisible,
                            visualViewport: layout.mapVisualViewport,
                            usesDuoDrawingContainer: true,
                            interactionViewport: layout.mapInteractionViewport,
                            onCitySelected: presentMapCityDetails(for:)
                        )
                        .position(x: layout.mapDrawingFrame.midX, y: layout.mapDrawingFrame.midY)
                        .opacity(mapVisible ? 1 : 0)
                        .allowsHitTesting(mapVisible)
                        .accessibilityHidden(!mapVisible)
                        .onAppear {
                            if !mapHasBeenPresented && layout.isInner {
                                mapHorizontalPosition = layout.isPortrait
                                    ? WorldMapGeometryProfile.duoPortraitInitialCenter
                                    : WorldMapGeometryProfile.duoInitialCenter
                            }
                            mapHasBeenPresented = true
                            duoMapMounted = true
                        }
                    }
                    // This controller stays mounted, including while empty or hidden.
                    CityListStoreObservation(cityStore: cityStore) { cities in
                        CityListReorderUIKitView(
                            cities: cities, selectedInstant: instant,
                            userCurrentLocationItem: currentLocationProvider.currentCityItem,
                            topSafeAreaInset: layout.listTopInset,
                            bottomContentInset: layout.isInner ? layout.bottomInset : 130,
                            onRenameRequested: presentRenameSheet(for:),
                            onCitySelected: presentCityDetails(for:),
                            duoViewport: layout.listViewport.size,
                            duoShowsLogo: !layout.isPortrait,
                            duoHorizontalInset: layout.listHorizontalInset
                        )
                    }
                    .frame(width: layout.listViewport.width, height: layout.listViewport.height)
                    .position(x: layout.listViewport.midX, y: layout.listViewport.midY)
                    .opacity(listVisible && !cityStore.cities.isEmpty ? 1 : 0)
                    .allowsHitTesting(listVisible && !cityStore.cities.isEmpty)
                    .accessibilityHidden(!listVisible || cityStore.cities.isEmpty)

                    if listVisible && cityStore.cities.isEmpty {
                        MainEmptyStateQuoteView(quote: emptyStateQuoteProvider.currentQuote)
                            .frame(width: layout.listViewport.width, height: layout.listViewport.height)
                            .position(x: layout.listViewport.midX, y: layout.listViewport.midY)
                            .allowsHitTesting(false)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    emptyStateQuoteProvider.randomizeQuote()
                                }
                            }
                            .overlay {
                                ShakeDetectorView { changeQuote() }
                                    .allowsHitTesting(false)
                            }
                    }
                    if layout.isPortrait || (listVisible && cityStore.cities.isEmpty) || (!layout.isInner && mapVisible) {
                        Image("HoursLogo").resizable().scaledToFit()
                            .frame(width: logoWidth, height: logoHeight)
                            .position(x: layout.isPortrait ? layout.map.midX : layout.listViewport.midX + 3,
                                      y: layout.isPortrait ? layout.map.minY + 49.5 : layout.listViewport.minY + 32.5)
                            .allowsHitTesting(false)
                    }
                    if !layout.isPortrait {
                        ProgressiveBottomBlurOverlay(height: layout.blurHeight)
                            .frame(width: layout.blurFrame.width, height: layout.blurHeight)
                            .position(x: layout.blurFrame.midX, y: layout.blurFrame.midY)
                            .allowsHitTesting(false)
                    }
                    duoWheel(layout: layout, geometry: geometry, rotation: rotation, steps: steps, reset: reset)
                    DeltaPillView(mode: mode, deltaText: delta, onTapReset: resetToNow, isDuoPresentation: true)
                        .position(x: layout.deltaCenter.x, y: layout.deltaCenter.y)
                    if !layout.isInner {
                        CityPresentationSwitcher(
                            presentation: $cityPresentation,
                            selectedInstant: instant,
                            cityStore: cityStore
                        )
                            .position(x: layout.outerSwitcherFrame?.midX ?? layout.map.minX + 55,
                                      y: layout.outerSwitcherFrame?.midY ?? layout.map.maxY - 48)
                    }
                    if let frame = layout.controls {
                        GlassEffectContainer(spacing: 10) {
                            VStack(spacing: 10) {
                                settingsButton()
                                addButton(iconOnly: true, symbol: "plus.circle.fill")
                            }
                        }
                        .frame(width: frame.width, height: frame.height)
                        .position(x: frame.midX, y: frame.midY)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .onAppear {
                    prepareDialHaptics()
                    resetNotificationHaptics.prepare()
                    lastSnappedOffsetSteps = viewModel.dialSteps
                    currentLocationProvider.requestCurrentCity()
                }
                .onChange(of: steps) { _, step in
                    guard step != lastSnappedOffsetSteps else { return }
                    fireHapticForSnappedStep(step)
                    lastSnappedOffsetSteps = step
                }
            }
            .onChange(of: layout.usesCompactSettingsHeader, initial: true) { _, value in
                usesCompactSettingsHeader = value
            }
        }
    }

    private func duoWheel(layout: DuoLayoutConfiguration, geometry: GeometryProxy,
                          rotation: Double, steps: Int, reset: Int) -> some View {
        let wheelBounds = CGRect(x: layout.wheelCenter.x - dialSize / 2,
                                 y: layout.wheelCenter.y - dialSize / 2,
                                 width: dialSize, height: dialSize)
        // A drawing clip alone does not restrict SwiftUI hit testing. Keep the
        // container itself inside the visible wheel bounds so the list and map
        // receive gestures everywhere above the arc.
        let intersection = layout.wheelClip.intersection(wheelBounds)
        let clip = intersection.isNull ? CGRect.zero : intersection
        return TimeDialView(
            diameter: dialSize, rotationDegrees: rotation, stepIndex: steps,
            resetSignal: reset, maxInteractiveGlobalY: geometry.frame(in: .global).minY + layout.map.maxY - 16,
            onDragBegan: {
                guard !isDraggingSessionActive else { return }
                isDraggingSessionActive = true
                viewModel.beginDialDrag()
                prepareDialHaptics()
            },
            onDragChanged: { value in
                guard isDraggingSessionActive else { return }
                viewModel.updateDialRotation(value)
            },
            onDragEnded: { current, predicted in
                guard isDraggingSessionActive else { return }
                isDraggingSessionActive = false
                viewModel.endDialDrag(currentRotation: current, predictedRotation: predicted)
            },
            onDragCancelled: cancelDialDrag,
            layoutCancellationFrame: CGRect(x: layout.wheelCenter.x - 256, y: layout.wheelCenter.y - 256, width: clip.width, height: clip.height)
        )
        .position(x: layout.wheelCenter.x - clip.minX, y: layout.wheelCenter.y - clip.minY)
        .frame(width: clip.width, height: clip.height)
        .clipped()
        .contentShape(Rectangle())
        .position(x: clip.midX, y: clip.midY)
    }

    private var persistenceAlertStatus: PersistenceAlertStatus {
        switch cityStore.persistenceStatus {
        case .loading: return .loading
        case .loaded: return .loaded
        case .fileAbsent: return .fileAbsent
        case .loadFailed: return .loadFailed
        case .unavailable: return .unavailable
        case .saveFailed: return .saveFailed
        }
    }

    private func updatePersistenceAlert() {
        switch persistenceAlertStatus {
        case .loading:
            return
        case .loaded, .fileAbsent:
            hasAcknowledgedPersistenceFailure = false
            isPersistenceAlertPresented = false
            return
        case .loadFailed, .unavailable, .saveFailed:
            break
        }

        guard !hasAcknowledgedPersistenceFailure,
              !isPersistenceAlertPresented,
              scenePhase == .active,
              hasCompletedOnboarding,
              sheetsAwaitingDismissal.isEmpty,
              !isAddCitySheetPresented, !isSettingsSheetPresented,
              cityBeingRenamed == nil, cityDetailsPresentation == nil else { return }

        hasAcknowledgedPersistenceFailure = true
        isPersistenceAlertPresented = true
    }

    private func persistenceSheetDidDismiss(_ sheet: PresentedSheet) {
        sheetsAwaitingDismissal.remove(sheet)
        updatePersistenceAlert()
    }

    private func topButtonBar() -> some View {
        GlassEffectContainer(spacing: 10) {
            HStack {
                addButton(iconOnly: false)
                Spacer(minLength: 0)
                settingsButton()
            }
            .padding(.horizontal, 20)
        }
    }

    // Read presentation bindings below the geometry boundary, just as live time
    // is observed there. Neither child owns the model or the presentation state.
    private struct CityPresentationContent<ListContent: View, MapContent: View>: View {
        @Binding var presentation: CityPresentation
        let isCitiesEmpty: Bool
        @ViewBuilder let list: () -> ListContent
        @ViewBuilder let map: () -> MapContent

        var body: some View {
            Group {
                if presentation == .map {
                    map()
                } else {
                    list()
                }
            }
            .zIndex(isCitiesEmpty && presentation == .list ? 1 : 0)
        }
    }

    // Observe below the deferred dial builder so city changes refresh the clock
    // without waiting for an unrelated dial-model publication.
    private struct CityPresentationSwitcher: View {
        @Binding var presentation: CityPresentation
        let selectedInstant: Date
        @ObservedObject var cityStore: CityStore

        var body: some View {
            CityPresentationButton(
                presentation: $presentation,
                selectedInstant: selectedInstant,
                primaryTimeZone: cityStore.cities.primaryCity?.timeZone ?? .current
            )
        }
    }

    private struct CityPresentationButton: View {
        @Binding var presentation: CityPresentation
        let selectedInstant: Date
        let primaryTimeZone: TimeZone

        var body: some View {
            Button {
                let previousPresentation = presentation
                presentation = presentation == .list ? .map : .list
                guard presentation != previousPresentation else { return }
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            } label: {
                Group {
                    if presentation == .list {
                        Image("map-button")
                            .renderingMode(.original)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                            .allowsHitTesting(false)
                    } else {
                        AnalogClockSwitcherIcon(instant: selectedInstant, timeZone: primaryTimeZone)
                    }
                }
                .frame(width: 48, height: 48)
                .modifier(GlassSurfaceModifier(shape: Circle()))
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(presentation == .list ? "Show Map" : "Show List")
            .accessibilityIdentifier("cityPresentationSwitcher")
        }
    }

    private func addButton(iconOnly: Bool, symbol: String = "plus.capsule.fill") -> some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            sheetsAwaitingDismissal.insert(.addCity)
            isAddCitySheetPresented = true
        }) {
            HStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .medium))
                if !iconOnly {
                    Text("Add")
                        .font(.system(size: 16, weight: .medium))
                        .tracking(-0.64)
                }
            }
            .modifier(TopBarForegroundStyle())
            .frame(width: iconOnly ? topButtonBarHeight : 87, height: topButtonBarHeight)
            .modifier(GlassSurfaceModifier(shape: Capsule()))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(iconOnly ? "Add City" : "Add")
    }

    private func settingsButton() -> some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            sheetsAwaitingDismissal.insert(.settings)
            isSettingsSheetPresented = true
        }) {
            Image(systemName: "line.3.horizontal.decrease")
                .font(.system(size: 16, weight: .medium))
                .modifier(TopBarForegroundStyle())
                .frame(width: topButtonBarHeight, height: topButtonBarHeight)
                .modifier(GlassSurfaceModifier(shape: Circle()))
        }
        .buttonStyle(.plain)
    }

    private func dialOverlay(
        in geo: GeometryProxy,
        rotationDegrees: Double,
        stepIndex: Int,
        resetSignal: Int,
        mode: DeltaPillView.PillMode,
        deltaText: String
    ) -> some View {
        ZStack(alignment: .bottom) {
            TimeDialView(
                diameter: dialSize,
                rotationDegrees: rotationDegrees,
                stepIndex: stepIndex,
                resetSignal: resetSignal,
                maxInteractiveGlobalY: geo.frame(in: .global).maxY - 16,
                onDragBegan: {
                    guard !isDraggingSessionActive else { return }
                    isDraggingSessionActive = true
                    viewModel.beginDialDrag()
                    prepareDialHaptics()
                    log("[DIAL] drag begin")
                },
                onDragChanged: { rotation in
                    guard isDraggingSessionActive else { return }
                    viewModel.updateDialRotation(rotation)
                },
                onDragEnded: { currentRotation, predictedRotation in
                    guard isDraggingSessionActive else { return }
                    log("[DIAL] drag end")
                    isDraggingSessionActive = false
                    viewModel.endDialDrag(currentRotation: currentRotation, predictedRotation: predictedRotation)
                },
                onDragCancelled: cancelDialDrag
            )
            .position(x: geo.size.width / 2, y: dialOverlayHeight + dialCenterYOffset)
            .allowsHitTesting(true)

            DeltaPillView(
                mode: mode,
                deltaText: deltaText,
                onTapReset: resetToNow
            )
            .padding(.bottom, 32)
            .allowsHitTesting(true)
        }
        .frame(maxWidth: .infinity)
        .frame(height: dialOverlayHeight + geo.safeAreaInsets.bottom, alignment: .bottom)
        .padding(.bottom, geo.safeAreaInsets.bottom)
        .allowsHitTesting(true)
    }

    private func cancelDialDrag() {
        guard isDraggingSessionActive else { return }
        isDraggingSessionActive = false
        viewModel.cancelDialDrag()
    }

    private func resetToNow() {
        cancelDialDrag()
        withAnimation(.spring(response: 0.36, dampingFraction: 0.86)) {
            viewModel.resetToNow()
        }
        resetNotificationHaptics.notificationOccurred(.success)
        resetNotificationHaptics.prepare()
    }

    private func fireHapticForSnappedStep(_ offsetSteps: Int) {
        guard hapticsEnabled else { return }

        if offsetSteps == 0 {
            zeroTickHaptics.notificationOccurred(.success)
            zeroTickHaptics.prepare()
            return
        }

        if abs(offsetSteps).isMultiple(of: 12) {
            bigTickHaptics.impactOccurred()
            bigTickHaptics.prepare()
            return
        }

        smallTickHaptics.impactOccurred()
        smallTickHaptics.prepare()
    }

    private func prepareDialHaptics() {
        guard hapticsEnabled else { return }
        smallTickHaptics.prepare()
        bigTickHaptics.prepare()
        zeroTickHaptics.prepare()
    }

    private func resolvedTopSafeAreaInset(from geometry: GeometryProxy) -> CGFloat {
        max(geometry.safeAreaInsets.top, Self.keyWindowTopSafeAreaInset())
    }

    private static func keyWindowTopSafeAreaInset() -> CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .safeAreaInsets.top ?? 0
    }

    private func log(_ message: String) {
        #if DEBUG
        print(message)
        #endif
    }

    private func appendCityIfNeeded(_ selectedItem: CitySearchItem) {
        let alreadyExists = cityStore.cities.contains(where: { $0.id == selectedItem.canonicalIdentity })
        guard !alreadyExists else {
            return
        }

        cityStore.cities.append(selectedItem.asCity)
    }

    private func presentRenameSheet(for city: City) {
        sheetsAwaitingDismissal.insert(.rename)
        cityBeingRenamed = city
    }

    private func applyCustomDisplayName(_ customName: String?, toCityID cityID: City.ID) {
        guard let index = cityStore.cities.firstIndex(where: { $0.id == cityID }) else { return }
        cityStore.cities[index].customDisplayName = customName
    }

    private func presentMapCityDetails(for cityID: City.ID) {
        // Resolve at activation, including after a menu has been open. A removed
        // city is a no-op; names, primary city and time all use current app state.
        guard let city = cityStore.cities.first(where: { $0.id == cityID }) else { return }
        presentCityDetails(for: city)
    }

    private func presentCityDetails(for city: City) {
        sheetsAwaitingDismissal.insert(.cityDetails)
        cityDetailsPresentation = CityDetailsPresentation(
            city: city,
            primaryCity: cityStore.cities.primaryCity ?? city,
            date: viewModel.selectedInstant,
            relativeOffsetMinutes: viewModel.deltaMinutes,
            cityViewPreference: selectedCityViewPreference
        )
    }

    private func changeQuote() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        withAnimation(.easeInOut(duration: 0.25)) {
            emptyStateQuoteProvider.randomizeQuote()
        }
    }
}

// The screen's builders can outlive the TimeDialScreen value they captured.
// Read appearance here so the existing buttons update without rebuilding them.
private struct TopBarForegroundStyle: ViewModifier {
    @Environment(\.appTheme) private var theme

    func body(content: Content) -> some View {
        content.foregroundStyle(theme.textPrimary.opacity(0.90))
    }
}

// Observe below the geometry boundary; invoke the builder with fresh model values.
private struct TimeDialObservedContent<Content: View>: View {
    @ObservedObject var viewModel: TimeDialViewModel
    @ViewBuilder let content: (Date, Double, Int, Int, DeltaPillView.PillMode, String) -> Content

    var body: some View {
        let selectedInstant = viewModel.selectedInstant
        let rotationDegrees = viewModel.rotationDegrees
        let dialSteps = viewModel.dialSteps
        let resetSignal = viewModel.resetSignal
        let mode = pillMode
        let deltaText = absDeltaString

        content(selectedInstant, rotationDegrees, dialSteps, resetSignal, mode, deltaText)
    }

    private var absDeltaString: String {
        let minutes = abs(viewModel.deltaMinutes)
        let hours = minutes / 60
        let mins = minutes % 60
        return "\(hours):" + String(format: "%02d", mins)
    }

    private var pillMode: DeltaPillView.PillMode {
        switch viewModel.mode {
        case .now: return .now
        case .future: return .future
        case .past: return .past
        }
    }
}

private struct DialOverlayHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct ShakeDetectorView: UIViewRepresentable {
    var onShake: () -> Void

    func makeUIView(context: Context) -> ShakeDetector {
        let view = ShakeDetector()
        view.onShake = onShake
        return view
    }

    func updateUIView(_ uiView: ShakeDetector, context: Context) {
        uiView.onShake = onShake
    }
}

private final class ShakeDetector: UIView {
    var onShake: (() -> Void)?

    override var canBecomeFirstResponder: Bool { true }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        becomeFirstResponder()
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard motion == .motionShake else { return }
        onShake?()
    }
}

// Observe city mutations below deferred geometry/dial closures, even while the
// ticker is paused. This forwards the original store binding to the retained list.
private struct CityListStoreObservation<Content: View>: View {
    @ObservedObject var cityStore: CityStore
    @ViewBuilder let content: (Binding<[City]>) -> Content

    var body: some View {
        let _ = cityStore.cities
        content($cityStore.cities)
    }
}

private struct CityListReorderUIKitView: UIViewControllerRepresentable {
    // Observe appearance below the deferred geometry boundary.
    @Environment(\.appTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    @Binding var cities: [City]
    let selectedInstant: Date
    let userCurrentLocationItem: CitySearchItem?
    // Observe at the native list boundary, below deferred geometry/content closures.
    @AppStorage(CityViewPreference.storageKey) private var cityViewPreferenceRawValue = CityViewPreference.basic.rawValue
    private var cityViewPreference: CityViewPreference {
        CityViewPreference.from(rawValue: cityViewPreferenceRawValue)
    }
    @AppStorage(AppTimeFormatPreference.storageKey) private var timeFormatPreference = AppTimeFormatPreference.system.rawValue
    let topSafeAreaInset: CGFloat
    let bottomContentInset: CGFloat
    let onRenameRequested: (City) -> Void
    let onCitySelected: (City) -> Void
    var duoViewport: CGSize? = nil
    var duoShowsLogo = true
    var duoHorizontalInset: CGFloat = 8

    final class Coordinator {
        var parent: CityListReorderUIKitView

        init(parent: CityListReorderUIKitView) {
            self.parent = parent
        }

        func publishCities(_ cities: [City]) {
            DispatchQueue.main.async {
                self.parent.cities = cities
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> CityListReorderViewController {
        let controller = CityListReorderViewController()
        controller.onCitiesChanged = { [weak coordinator = context.coordinator] updatedCities in
            coordinator?.publishCities(updatedCities)
        }
        controller.onRenameRequested = { [weak coordinator = context.coordinator] city in
            coordinator?.parent.onRenameRequested(city)
        }
        controller.onCitySelected = { [weak coordinator = context.coordinator] city in
            coordinator?.parent.onCitySelected(city)
        }
        controller.updateCardTheme(theme)
        controller.prepareDuoLayout(viewport: duoViewport, showsLogo: duoShowsLogo, horizontalInset: duoHorizontalInset)
        controller.apply(
            cities: cities,
            selectedInstant: selectedInstant,
            userCurrentLocationItem: userCurrentLocationItem,
            cityViewPreference: cityViewPreference,
            topInset: topSafeAreaInset,
            bottomInset: bottomContentInset,
            cardBackgroundColor: SheetStyle.appCardBackground(for: theme)
        )
        controller.updatePortraitBlur(theme: theme, colorScheme: colorScheme)
        return controller
    }

    func updateUIViewController(_ uiViewController: CityListReorderViewController, context: Context) {
        _ = timeFormatPreference
        context.coordinator.parent = self
        uiViewController.onCitiesChanged = { [weak coordinator = context.coordinator] updatedCities in
            coordinator?.publishCities(updatedCities)
        }
        uiViewController.onRenameRequested = { [weak coordinator = context.coordinator] city in
            coordinator?.parent.onRenameRequested(city)
        }
        uiViewController.onCitySelected = { [weak coordinator = context.coordinator] city in
            coordinator?.parent.onCitySelected(city)
        }
        uiViewController.updateCardTheme(theme)
        uiViewController.prepareDuoLayout(viewport: duoViewport, showsLogo: duoShowsLogo, horizontalInset: duoHorizontalInset)
        uiViewController.apply(
            cities: cities,
            selectedInstant: selectedInstant,
            userCurrentLocationItem: userCurrentLocationItem,
            cityViewPreference: cityViewPreference,
            topInset: topSafeAreaInset,
            bottomInset: bottomContentInset,
            cardBackgroundColor: SheetStyle.appCardBackground(for: theme)
        )
        uiViewController.updatePortraitBlur(theme: theme, colorScheme: colorScheme)
    }
}

private struct PortraitCityListBlur: View {
    let theme: AppTheme
    let colorScheme: ColorScheme
    var body: some View {
        ProgressiveBottomBlurOverlay(height: 40, lightTint: theme.screenBackground)
            .frame(height: 40)
            .rotationEffect(.degrees(180))
            .clipped()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .environment(\.appTheme, theme)
            .environment(\.colorScheme, colorScheme)
    }
}

private final class CityListReorderViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate {
    private static var didPrintBottomInsetProbe = false
    private static let logoHeaderReuseIdentifier = "CityListLogoHeaderView"
    private static let logoHeight: CGFloat = 15
    private static let logoWidth: CGFloat = 49
    private static let logoBottomSpacing: CGFloat = 33

    private struct PendingExternalState {
        let cities: [City]
        let selectedInstant: Date
        let userCurrentLocationItem: CitySearchItem?
        let cityViewPreference: CityViewPreference
        let topInset: CGFloat
        let bottomInset: CGFloat
        let cardBackgroundColor: Color
    }

    var onCitiesChanged: (([City]) -> Void)?
    var onRenameRequested: ((City) -> Void)?
    var onCitySelected: ((City) -> Void)?

    private lazy var collectionViewLayout: UICollectionViewCompositionalLayout = {
        var listConfiguration = UICollectionLayoutListConfiguration(appearance: .plain)
        listConfiguration.showsSeparators = false
        listConfiguration.headerMode = .supplementary
        listConfiguration.headerTopPadding = 0
        listConfiguration.backgroundColor = .clear
        listConfiguration.trailingSwipeActionsConfigurationProvider = { [weak self] indexPath in
            self?.trailingSwipeActionsConfiguration(for: indexPath)
        }

        return UICollectionViewCompositionalLayout { [weak self] _, layoutEnvironment in
            var configuration = listConfiguration
            let portrait = self?.duoViewport != nil && self?.duoShowsLogo == false
            if portrait { configuration.headerMode = .none }
            if self?.cityViewPreference == .cards {
                let inset = self?.duoViewport == nil ? 8 : (self?.duoHorizontalInset ?? 8)
                let width = (layoutEnvironment.container.effectiveContentSize.width - inset * 2 - 8) / 2
                let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(
                    widthDimension: .absolute(max(1, width)), heightDimension: .absolute(200)))
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                       heightDimension: .absolute(200)),
                    subitems: [item, item])
                group.interItemSpacing = .fixed(8)
                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = 8
                section.contentInsets = NSDirectionalEdgeInsets(top: portrait ? self?.topInset ?? 20 : 0,
                                                               leading: inset, bottom: 0, trailing: inset)
                if !portrait {
                    let height = (self?.topInset ?? 0) + Self.logoHeight +
                        (self?.duoViewport == nil ? Self.logoBottomSpacing : 24)
                    section.boundarySupplementaryItems = [NSCollectionLayoutBoundarySupplementaryItem(
                        layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                           heightDimension: .absolute(height)),
                        elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)]
                }
                return section
            }
            let section = NSCollectionLayoutSection.list(
                using: configuration,
                layoutEnvironment: layoutEnvironment
            )
            section.interGroupSpacing = 8
            let inset = self?.duoViewport == nil ? 8 : (self?.duoHorizontalInset ?? 8)
            section.contentInsets = NSDirectionalEdgeInsets(top: portrait ? self?.topInset ?? 20 : 0,
                                                           leading: inset, bottom: 0, trailing: inset)
            return section
        }
    }()
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.topEdgeEffect.style = .soft
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.alwaysBounceVertical = true
        collectionView.dragInteractionEnabled = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            CityListReorderCollectionCell.self,
            forCellWithReuseIdentifier: CityListReorderCollectionCell.reuseIdentifier
        )
        collectionView.register(
            CityListLogoHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: Self.logoHeaderReuseIdentifier
        )
        return collectionView
    }()

    private lazy var longPressGestureRecognizer: UILongPressGestureRecognizer = {
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        recognizer.minimumPressDuration = 0.3
        recognizer.cancelsTouchesInView = false
        return recognizer
    }()

    private var openActionsCityID: City.ID?
    private var actionSwipeCityID: City.ID?
    private var actionSwipeStartProgress: CGFloat = 0
    private var actionSwipeWasOpen = false
    private var actionSwipeProgress: CGFloat = 0
    private lazy var cardActionPan: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handleCardActionPan(_:)))
        gesture.delegate = self
        gesture.isEnabled = false
        gesture.require(toFail: longPressGestureRecognizer)
        return gesture
    }()
    private lazy var dismissActionsTap: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleOutsideActionTap))
        gesture.cancelsTouchesInView = false
        gesture.delegate = self
        return gesture
    }()

    private var portraitBlur: UIHostingController<PortraitCityListBlur>?
    private var portraitBlurScheme: ColorScheme?
    private var portraitBlurBackground: Color?

    func updatePortraitBlur(theme: AppTheme, colorScheme: ColorScheme) {
        let enabled = duoViewport != nil && !duoShowsLogo
        if enabled && portraitBlur == nil {
            let host = UIHostingController(rootView: PortraitCityListBlur(theme: theme, colorScheme: colorScheme))
            host.safeAreaRegions = []
            addChild(host)
            host.view.backgroundColor = .clear
            host.view.isUserInteractionEnabled = false
            host.view.accessibilityElementsHidden = true
            host.view.clipsToBounds = true
            host.view.alpha = 0
            view.addSubview(host.view)
            host.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                host.view.topAnchor.constraint(equalTo: view.topAnchor),
                host.view.heightAnchor.constraint(equalToConstant: 40)
            ])
            host.didMove(toParent: self)
            portraitBlur = host
        }
        if enabled, portraitBlurScheme != colorScheme || portraitBlurBackground != theme.screenBackground {
            portraitBlur?.rootView = PortraitCityListBlur(theme: theme, colorScheme: colorScheme)
            portraitBlurScheme = colorScheme
            portraitBlurBackground = theme.screenBackground
        }
        portraitBlur?.view.isHidden = !enabled
        updatePortraitBlurOpacity()
    }

    private func updatePortraitBlurOpacity() {
        guard let overlay = portraitBlur?.view else { return }
        let distance = max(0, collectionView.contentOffset.y + collectionView.adjustedContentInset.top)
        let progress = min(1, distance / 40)
        // Smoothstep follows scrolling directly, with no animation or layout work.
        UIView.performWithoutAnimation {
            overlay.alpha = progress * progress * (3 - 2 * progress)
        }
    }

    func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
        updatePortraitBlurOpacity()
    }

    private var duoViewport: CGSize?
    private var duoShowsLogo = true
    private var duoHorizontalInset: CGFloat = 8
    private struct ScrollAnchor {
        let candidates: [City.ID]
        let offset: CGFloat
        let isAtTop: Bool
    }
    private var duoScrollAnchor: ScrollAnchor?
    private var lastDuoScrollAnchor: ScrollAnchor?

    private func captureDuoScrollAnchor() -> ScrollAnchor? {
        let y = collectionView.contentOffset.y
        guard let visible = collectionView.indexPathsForVisibleItems.sorted().first(where: {
            (collectionView.layoutAttributesForItem(at: $0)?.frame.maxY ?? 0) > y
        }), citiesLocal.indices.contains(visible.item),
            let frame = collectionView.layoutAttributesForItem(at: visible)?.frame else { return nil }
        let candidates = Array(citiesLocal[visible.item...].map(\.id)) + citiesLocal[..<visible.item].reversed().map(\.id)
        return ScrollAnchor(candidates: candidates, offset: y - frame.minY, isAtTop: y <= 0)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updatePortraitBlurOpacity()
        if isReordering, cityViewPreference == .cards, let point = dragPointInViewport {
            collectionView.updateInteractiveMovementTargetPosition(CGPoint(
                x: point.x + collectionView.bounds.minX, y: point.y + collectionView.bounds.minY))
        }
        // UIKit may adjust its offset before SwiftUI supplies the new pane size.
        // Preserve the last user anchor, not that transient automatic adjustment.
        guard duoViewport != nil, duoScrollAnchor == nil,
              scrollView.isDragging || scrollView.isDecelerating || isReordering else { return }
        lastDuoScrollAnchor = captureDuoScrollAnchor()
    }

    func prepareDuoLayout(viewport: CGSize?, showsLogo: Bool = true, horizontalInset: CGFloat = 8) {
        guard viewport != duoViewport || showsLogo != duoShowsLogo || horizontalInset != duoHorizontalInset else { return }
        if duoViewport != nil {
            duoScrollAnchor = lastDuoScrollAnchor ?? captureDuoScrollAnchor()
            if isReordering {
                collectionView.cancelInteractiveMovement()
                finishInteractiveMovement()
            }
        }
        duoViewport = viewport
        duoShowsLogo = showsLogo
        duoHorizontalInset = horizontalInset
        if viewport != nil {
            collectionView.contentInsetAdjustmentBehavior = .never
            collectionView.automaticallyAdjustsScrollIndicatorInsets = false
        }
        collectionView.collectionViewLayout.invalidateLayout()
    }

    private var citiesLocal: [City] = []
    private var selectedInstant: Date = Date()
    private var topInset: CGFloat = 0
    private var bottomInset: CGFloat = 0
    private var userCurrentLocationItem: CitySearchItem?
    private var cityViewPreference: CityViewPreference = .basic
    private var cardBackgroundColor: Color = AppTheme.light.surfaceCard
    private var cardTheme: AppTheme?

    func updateCardTheme(_ theme: AppTheme) {
        // SwiftUI supplies the new theme before UIKit necessarily delivers its
        // trait change. Cards must not capture the previous trait's text colors.
        cardTheme = theme
    }
    private var isReordering = false
    private var isTapToOpenSuppressed = false
    private var pendingExternalState: PendingExternalState?
    private var needsPostAttachReload = false
    private var dragPointInViewport: CGPoint?
    private var isDragAutoScrolling = false
    private var reorderOriginalCities: [City]?
    private var draggedCityID: City.ID?
    private weak var liftedCell: CityListReorderCollectionCell?
    private var tapSuppressionResetWorkItem: DispatchWorkItem?
    private let deleteSuccessHaptics = UINotificationFeedbackGenerator()
    private let tapSuppressionDelay: TimeInterval = 0.2

    private var resolvedTheme: AppTheme {
        let colorScheme: ColorScheme = traitCollection.userInterfaceStyle == .dark ? .dark : .light
        return AppTheme.forColorScheme(colorScheme)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        longPressGestureRecognizer.delegate = self
        collectionView.addGestureRecognizer(longPressGestureRecognizer)
        collectionView.addGestureRecognizer(cardActionPan)
        collectionView.panGestureRecognizer.require(toFail: cardActionPan)
        applySectionInsets()
        deleteSuccessHaptics.prepare()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applySectionInsets()
        if duoViewport != nil, let anchor = duoScrollAnchor {
            duoScrollAnchor = nil
            collectionView.layoutIfNeeded()
            if let id = anchor.candidates.first(where: { id in citiesLocal.contains(where: { $0.id == id }) }),
               let index = citiesLocal.firstIndex(where: { $0.id == id }) {
                let path = IndexPath(item: index, section: 0)
                // Materialize the anchor before reading its frame. List layouts
                // otherwise return estimated positions for newly exposed rows.
                if !anchor.isAtTop {
                    collectionView.scrollToItem(at: path, at: .top, animated: false)
                    collectionView.layoutIfNeeded()
                }
                let frame = collectionView.layoutAttributesForItem(at: path)?.frame ?? .zero
                let maximum = max(0, collectionView.contentSize.height + collectionView.contentInset.bottom - collectionView.bounds.height)
                let offset = anchor.isAtTop ? 0 : min(maximum, max(0, frame.minY + anchor.offset))
                collectionView.setContentOffset(CGPoint(x: 0, y: offset), animated: false)
            }
        }
        if duoViewport != nil, lastDuoScrollAnchor == nil {
            lastDuoScrollAnchor = captureDuoScrollAnchor()
        }
        updatePortraitBlurOpacity()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if dismissActionsTap.view !== view.window {
            view.window?.addGestureRecognizer(dismissActionsTap)
        }
        runPostAttachReloadIfNeeded()
        updatePortraitBlurOpacity()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        setOpenActionsCityID(nil)
        dismissActionsTap.view?.removeGestureRecognizer(dismissActionsTap)
    }

    func apply(
        cities: [City],
        selectedInstant: Date,
        userCurrentLocationItem: CitySearchItem?,
        cityViewPreference: CityViewPreference,
        topInset: CGFloat,
        bottomInset: CGFloat,
        cardBackgroundColor: Color
    ) {
        if isReordering {
            pendingExternalState = PendingExternalState(
                cities: cities,
                selectedInstant: selectedInstant,
                userCurrentLocationItem: userCurrentLocationItem,
                cityViewPreference: cityViewPreference,
                topInset: topInset,
                bottomInset: bottomInset,
                cardBackgroundColor: cardBackgroundColor
            )
            return
        }

        self.selectedInstant = selectedInstant
        self.cardBackgroundColor = cardBackgroundColor
        let didCurrentLocationChange = self.userCurrentLocationItem != userCurrentLocationItem
        self.userCurrentLocationItem = userCurrentLocationItem
        let didCityViewPreferenceChange = self.cityViewPreference != cityViewPreference
        self.cityViewPreference = cityViewPreference
        if didCityViewPreferenceChange {
            resetCardActionPresentation()
            openActionsCityID = nil
            cardActionPan.isEnabled = cityViewPreference == .cards
            collectionView.collectionViewLayout.invalidateLayout()
        }
        if let id = openActionsCityID, !cities.contains(where: { $0.id == id }) {
            // The city is leaving the data source during representable update;
            // retire its presentation instead of animating the outgoing host.
            resetCardActionPresentation()
            openActionsCityID = nil
        }
        if let id = actionSwipeCityID, !cities.contains(where: { $0.id == id }) {
            resetCardActionPresentation()
        }

        let insetsChanged = self.topInset != topInset || self.bottomInset != bottomInset
        if insetsChanged {
            self.topInset = topInset
            self.bottomInset = bottomInset
            applySectionInsets()
            collectionView.collectionViewLayout.invalidateLayout()
        }

        if cities.isEmpty && needsPostAttachReload {
            needsPostAttachReload = false
        }

        if cities.count > 0, !isRenderReadyForNonEmptyReload {
            needsPostAttachReload = true
        }

        if citiesLocal != cities {
            citiesLocal = cities
            collectionView.reloadData()
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.collectionView.layoutIfNeeded()
            }
            return
        }

        if didCurrentLocationChange {
            collectionView.reloadData()
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.collectionView.layoutIfNeeded()
            }
            return
        }

        if didCityViewPreferenceChange {
            collectionView.collectionViewLayout.invalidateLayout()
            collectionView.reloadData()
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.collectionView.layoutIfNeeded()
            }
            return
        }

        reconfigureVisibleCells()
    }

    private func applySectionInsets() {
        applyDeterministicBottomInset()
    }

    private func applyDeterministicBottomInset() {
        let desiredGap = bottomInset
        let safeBottom = duoViewport == nil ? collectionView.safeAreaInsets.bottom : 0
        // Keep UIKit automatic safe-area adjustment enabled, so adjusted bottom becomes:
        // adjusted = contentInset.bottom + safeBottom ~= desiredGap (130pt target).
        let targetContentInsetBottom = max(0, desiredGap - safeBottom)
        let epsilon: CGFloat = 0.5

        if abs(collectionView.contentInset.bottom - targetContentInsetBottom) > epsilon {
            collectionView.contentInset = UIEdgeInsets(
                top: collectionView.contentInset.top,
                left: collectionView.contentInset.left,
                bottom: targetContentInsetBottom,
                right: collectionView.contentInset.right
            )
        }
        if abs(collectionView.verticalScrollIndicatorInsets.bottom - targetContentInsetBottom) > epsilon {
            collectionView.verticalScrollIndicatorInsets = UIEdgeInsets(
                top: collectionView.verticalScrollIndicatorInsets.top,
                left: collectionView.verticalScrollIndicatorInsets.left,
                bottom: targetContentInsetBottom,
                right: collectionView.verticalScrollIndicatorInsets.right
            )
        }

        #if DEBUG
        if !Self.didPrintBottomInsetProbe {
            print(
                "[SCROLLPROBE] desiredGap=\(desiredGap) safeBottom=\(safeBottom) " +
                "contentInsetBottom=\(collectionView.contentInset.bottom) " +
                "adjustedInsetBottom=\(collectionView.adjustedContentInset.bottom)"
            )
            Self.didPrintBottomInsetProbe = true
        }
        #endif
    }

    private var isRenderReadyForNonEmptyReload: Bool {
        let hasNonZeroBounds = collectionView.bounds.width > 0 && collectionView.bounds.height > 0
        return view.window != nil && hasNonZeroBounds
    }

    private func runPostAttachReloadIfNeeded() {
        guard needsPostAttachReload else { return }
        guard !citiesLocal.isEmpty else { return }
        guard isRenderReadyForNonEmptyReload else { return }

        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
        needsPostAttachReload = false
    }

    private func reconfigureVisibleCells() {
        let matchedCurrentLocationIndex = currentLocationMatchIndex()

        for indexPath in collectionView.indexPathsForVisibleItems {
            guard indexPath.item < citiesLocal.count else { continue }
            guard let cell = collectionView.cellForItem(at: indexPath) as? CityListReorderCollectionCell else { continue }

            let city = citiesLocal[indexPath.item]
            let referenceTimeZone = citiesLocal.primaryCity?.timeZone ?? city.timeZone
            cell.configure(
                city: city,
                selectedInstant: selectedInstant,
                referenceTimeZone: referenceTimeZone,
                isCurrent: city.id == citiesLocal.primaryCity?.id,
                isUserCurrentLocation: matchedCurrentLocationIndex == indexPath.item,
                cityViewPreference: cityViewPreference,
                cardBackgroundColor: cardBackgroundColor,
                isDuoPresentation: duoViewport != nil,
                cardTheme: cityViewPreference == .cards ? cardTheme : nil,
                showsActions: openActionsCityID == city.id,
                onRename: { [weak self] in self?.renameCity(id: city.id) },
                onDelete: { [weak self] in self?.deleteCity(id: city.id) },
                onOpenDetails: { [weak self] in self?.selectCity(id: city.id) }
            )
        }
    }

    private func currentLocationMatchIndex() -> Int? {
        guard let userCurrentLocationItem else { return nil }
        guard !citiesLocal.isEmpty else { return nil }

        let currentCanonicalID = userCurrentLocationItem.canonicalIdentity
        let normalizedCurrentCity = normalized(userCurrentLocationItem.city)
        let currentTimeZoneID = userCurrentLocationItem.timeZoneIdentifier.lowercased()

        if let canonicalMatchIndex = citiesLocal.firstIndex(where: {
            !$0.isZeroOffsetReferenceCity &&
            $0.id == currentCanonicalID
        }) {
            return canonicalMatchIndex
        }

        if let exactMatchIndex = citiesLocal.firstIndex(where: {
            !$0.isZeroOffsetReferenceCity &&
            $0.timeZoneID.lowercased() == currentTimeZoneID &&
            normalized($0.name) == normalizedCurrentCity
        }) {
            return exactMatchIndex
        }

        let timeZoneMatchIndices = citiesLocal.indices.filter { index in
            let city = citiesLocal[index]
            return !city.isZeroOffsetReferenceCity &&
                city.timeZoneID.lowercased() == currentTimeZoneID
        }
        if timeZoneMatchIndices.count == 1, let onlyMatch = timeZoneMatchIndices.first {
            return onlyMatch
        }

        let cityNameMatchIndices = citiesLocal.indices.filter { index in
            let city = citiesLocal[index]
            return !city.isZeroOffsetReferenceCity &&
                normalized(city.name) == normalizedCurrentCity
        }
        if cityNameMatchIndices.count == 1, let onlyMatch = cityNameMatchIndices.first {
            return onlyMatch
        }

        return nil
    }

    private func normalized(_ input: String) -> String {
        input
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    @objc
    private func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
        let location = recognizer.location(in: collectionView)

        switch recognizer.state {
        case .began:
            guard let indexPath = collectionView.indexPathForItem(at: location) else { return }
            guard indexPath.item < citiesLocal.count else { return }
            setOpenActionsCityID(nil)
            guard collectionView.beginInteractiveMovementForItem(at: indexPath) else { return }

            reorderOriginalCities = citiesLocal
            tapSuppressionResetWorkItem?.cancel()
            isTapToOpenSuppressed = true
            isReordering = true
            draggedCityID = citiesLocal[indexPath.item].id
            if let cell = collectionView.cellForItem(at: indexPath) as? CityListReorderCollectionCell {
                liftedCell = cell
                cell.setLifted(true)
            }

        case .changed:
            guard isReordering else { return }
            var target = location
            if cityViewPreference != .cards { target.x = collectionView.bounds.midX }
            updateInteractiveMovementTarget(target)

        case .ended:
            guard isReordering else { return }
            collectionView.endInteractiveMovement()
            finishInteractiveMovement()

        case .cancelled, .failed:
            guard isReordering else { return }
            collectionView.cancelInteractiveMovement()
            finishInteractiveMovement()

        default:
            guard isReordering else { return }
            collectionView.cancelInteractiveMovement()
            finishInteractiveMovement()
        }
    }

    private func updateInteractiveMovementTarget(_ target: CGPoint) {
        collectionView.updateInteractiveMovementTargetPosition(target)
        guard cityViewPreference == .cards else { return }
        dragPointInViewport = CGPoint(x: target.x - collectionView.bounds.minX,
                                      y: target.y - collectionView.bounds.minY)
        continueDragAutoScroll()
    }

    private func continueDragAutoScroll() {
        guard isReordering, cityViewPreference == .cards, let point = dragPointInViewport else { return }
        let insets = collectionView.adjustedContentInset
        let direction: CGFloat = point.y < insets.top + 48 ? -1 :
            (point.y > collectionView.bounds.height - insets.bottom - 48 ? 1 : 0)
        if direction == 0 {
            if isDragAutoScrolling {
                isDragAutoScrolling = false
                collectionView.setContentOffset(collectionView.contentOffset, animated: false)
            }
            return
        }
        guard !isDragAutoScrolling else { return }
        let minimum = -insets.top
        let maximum = max(minimum, collectionView.contentSize.height - collectionView.bounds.height + insets.bottom)
        let next = min(maximum, max(minimum, collectionView.contentOffset.y + direction * 104))
        guard abs(next - collectionView.contentOffset.y) > 0.5 else { return }
        // UIKit owns animation timing. Chain half-row steps only while a drag
        // remains at the edge; no timer, display link, or idle rendering loop.
        isDragAutoScrolling = true
        collectionView.setContentOffset(CGPoint(x: collectionView.contentOffset.x, y: next), animated: true)
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard isDragAutoScrolling else { return }
        isDragAutoScrolling = false
        continueDragAutoScroll()
    }

    private func finishInteractiveMovement() {
        isReordering = false
        dragPointInViewport = nil
        if isDragAutoScrolling {
            isDragAutoScrolling = false
            collectionView.setContentOffset(collectionView.contentOffset, animated: false)
        }
        liftedCell?.setLifted(false)
        liftedCell = nil

        let draggedID = draggedCityID
        draggedCityID = nil

        #if DEBUG
        if let draggedID, let finalIndex = citiesLocal.firstIndex(where: { $0.id == draggedID }) {
            print("[REORDER_UIKIT] end finalIndex=\(finalIndex)")
        } else {
            print("[REORDER_UIKIT] end finalIndex=-1")
        }
        #endif

        scheduleTapSuppressionReset()
        applyPendingExternalStateIfNeeded()
        reorderOriginalCities = nil
        reconfigureVisibleCells()
    }

    private func mergedPendingCities(_ incoming: [City]) -> [City] {
        guard let original = reorderOriginalCities,
              incoming.map(\.id) == original.map(\.id) else { return incoming }
        // Merge refreshed names/data by identity while retaining the committed order.
        let byID = Dictionary(uniqueKeysWithValues: incoming.map { ($0.id, $0) })
        return citiesLocal.compactMap { byID[$0.id] }
    }

    private func scheduleTapSuppressionReset() {
        tapSuppressionResetWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.isTapToOpenSuppressed = false
            self?.tapSuppressionResetWorkItem = nil
        }
        tapSuppressionResetWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + tapSuppressionDelay, execute: workItem)
    }

    private func applyPendingExternalStateIfNeeded() {
        guard let pendingExternalState else { return }
        self.pendingExternalState = nil
        apply(
            cities: mergedPendingCities(pendingExternalState.cities),
            selectedInstant: pendingExternalState.selectedInstant,
            userCurrentLocationItem: pendingExternalState.userCurrentLocationItem,
            cityViewPreference: pendingExternalState.cityViewPreference,
            topInset: pendingExternalState.topInset,
            bottomInset: pendingExternalState.bottomInset,
            cardBackgroundColor: pendingExternalState.cardBackgroundColor
        )
    }

    private func trailingSwipeActionsConfiguration(for indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !isReordering, cityViewPreference != .cards else { return nil }
        guard citiesLocal.indices.contains(indexPath.item) else { return nil }

        let renameAction = UIContextualAction(style: .normal, title: nil) { [weak self] _, _, completion in
            guard let self else {
                completion(false)
                return
            }
            guard self.citiesLocal.indices.contains(indexPath.item) else {
                completion(false)
                return
            }
            self.renameCity(id: self.citiesLocal[indexPath.item].id)
            completion(true)
        }
        renameAction.image = UIImage(systemName: "character.textbox")?.withTintColor(
            UIColor(resolvedTheme.textInverse),
            renderingMode: .alwaysOriginal
        )
        renameAction.backgroundColor = UIColor(resolvedTheme.textPrimary)

        let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] _, _, completion in
            guard let self else {
                completion(false)
                return
            }
            completion(deleteCity(at: indexPath))
        }
        deleteAction.image = UIImage(systemName: "trash.fill")
        deleteAction.backgroundColor = UIColor(resolvedTheme.accent)

        // UIKit trailing actions render first item on the far trailing edge.
        // Order here yields: Rename (near card), Delete (far right).
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, renameAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }

    private func actionCell(for id: City.ID) -> CityListReorderCollectionCell? {
        guard let index = citiesLocal.firstIndex(where: { $0.id == id }) else { return nil }
        return collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? CityListReorderCollectionCell
    }

    private func resetCardActionPresentation() {
        for cell in collectionView.visibleCells.compactMap({ $0 as? CityListReorderCollectionCell }) {
            cell.resetActionPresentation()
        }
        actionSwipeCityID = nil
        actionSwipeProgress = 0
    }

    private func setOpenActionsCityID(_ id: City.ID?) {
        let validID = cityViewPreference == .cards && !isReordering
            ? id.flatMap { id in citiesLocal.contains(where: { $0.id == id }) ? id : nil } : nil
        let affected = Set([openActionsCityID, actionSwipeCityID, validID].compactMap { $0 })
        openActionsCityID = validID
        actionSwipeCityID = nil
        actionSwipeProgress = 0
        for cityID in affected {
            actionCell(for: cityID)?.actionPresentation.settle(open: cityID == validID)
        }
    }

    private func renameCity(id: City.ID) {
        guard !isReordering, !isTapToOpenSuppressed,
              let city = citiesLocal.first(where: { $0.id == id }) else { return }
        setOpenActionsCityID(nil)
        triggerRenameHaptics()
        DispatchQueue.main.async { [weak self] in self?.onRenameRequested?(city) }
    }

    private func deleteCity(id: City.ID) {
        guard !isTapToOpenSuppressed, let index = citiesLocal.firstIndex(where: { $0.id == id }) else { return }
        deleteCity(at: IndexPath(item: index, section: 0))
    }

    private func selectCity(id: City.ID) {
        guard let index = citiesLocal.firstIndex(where: { $0.id == id }) else { return }
        setOpenActionsCityID(nil)
        collectionView(collectionView, didSelectItemAt: IndexPath(item: index, section: 0))
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === cardActionPan else { return true }
        let velocity = cardActionPan.velocity(in: collectionView)
        let location = cardActionPan.location(in: collectionView)
        let translation = cardActionPan.translation(in: collectionView)
        let point = CGPoint(x: location.x - translation.x, y: location.y - translation.y)
        return cityViewPreference == .cards && !isReordering &&
            abs(velocity.x) > abs(velocity.y) * 1.5 &&
            collectionView.indexPathForItem(at: point) != nil
    }

    private func isActionButtonPoint(_ point: CGPoint) -> Bool {
        guard let id = openActionsCityID, actionCell(for: id)?.actionPresentation.buttonsEnabled == true,
              let index = citiesLocal.firstIndex(where: { $0.id == id }),
              let frame = collectionView.layoutAttributesForItem(at: IndexPath(item: index, section: 0))?.frame else { return false }
        // The action area stays centered at y=100; hit regions match its controls.
        return [-CardsActionMetrics.centerOffset, CardsActionMetrics.centerOffset].contains { offset in
            hypot(point.x - frame.midX - offset, point.y - frame.minY - 100) <= CardsActionMetrics.diameter / 2
        }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let point = touch.location(in: collectionView)
        if gestureRecognizer === dismissActionsTap {
            return openActionsCityID != nil && !isActionButtonPoint(point)
        }
        if gestureRecognizer === longPressGestureRecognizer && cityViewPreference == .cards {
            return !isActionButtonPoint(point)
        }
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        gestureRecognizer === dismissActionsTap || otherGestureRecognizer === dismissActionsTap
    }

    @objc private func handleCardActionPan(_ recognizer: UIPanGestureRecognizer) {
        guard cityViewPreference == .cards, !isReordering else { return }
        switch recognizer.state {
        case .began:
            let location = recognizer.location(in: collectionView)
            let translation = recognizer.translation(in: collectionView)
            let point = CGPoint(x: location.x - translation.x, y: location.y - translation.y)
            actionSwipeCityID = collectionView.indexPathForItem(at: point).flatMap {
                citiesLocal.indices.contains($0.item) ? citiesLocal[$0.item].id : nil
            }
            guard let id = actionSwipeCityID else { return }
            actionSwipeWasOpen = openActionsCityID == id
            actionSwipeStartProgress = actionCell(for: id)?.actionPresentation.presentedProgress
                ?? (actionSwipeWasOpen ? 1 : 0)
            if let previous = openActionsCityID, previous != id {
                actionCell(for: previous)?.actionPresentation.settle(open: false)
                openActionsCityID = nil
            }
            updateCardActionSwipe(translation: translation.x)
        case .changed:
            updateCardActionSwipe(translation: recognizer.translation(in: collectionView).x)
        case .ended:
            let translation = recognizer.translation(in: collectionView)
            if translation.x < -24 { setOpenActionsCityID(actionSwipeCityID) }
            else if translation.x > 24 { setOpenActionsCityID(nil) }
            else { setOpenActionsCityID(actionSwipeWasOpen ? actionSwipeCityID : nil) }
        case .cancelled, .failed:
            setOpenActionsCityID(actionSwipeWasOpen ? actionSwipeCityID : nil)
        default: break
        }
    }

    private func updateCardActionSwipe(translation: CGFloat) {
        guard let id = actionSwipeCityID else { return }
        // Keep the existing 24pt commit threshold; 96pt gives the visual reveal
        // enough travel to follow a slow swipe without reaching its end instantly.
        actionSwipeProgress = min(1, max(0, actionSwipeStartProgress - translation / 96))
        actionCell(for: id)?.actionPresentation.updateInteractiveProgress(actionSwipeProgress)
    }

    @objc private func handleOutsideActionTap() {
        guard openActionsCityID != nil else { return }
        setOpenActionsCityID(nil)
        isTapToOpenSuppressed = true
        scheduleTapSuppressionReset()
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if cityViewPreference == .cards { setOpenActionsCityID(nil) }
    }

    private func triggerRenameHaptics() {
        let fire = {
            let haptics = UIImpactFeedbackGenerator(style: .medium)
            haptics.impactOccurred()
        }

        if Thread.isMainThread {
            fire()
        } else {
            DispatchQueue.main.async(execute: fire)
        }
    }

    @discardableResult
    private func deleteCity(at indexPath: IndexPath) -> Bool {
        guard !isReordering else { return false }
        guard citiesLocal.indices.contains(indexPath.item) else { return false }

        setOpenActionsCityID(nil)
        citiesLocal.remove(at: indexPath.item)
        let updatedCities = citiesLocal

        collectionView.performBatchUpdates {
            collectionView.deleteItems(at: [indexPath])
        } completion: { [weak self] _ in
            self?.reconfigureVisibleCells()
        }

        deleteSuccessHaptics.notificationOccurred(.success)
        deleteSuccessHaptics.prepare()
        DispatchQueue.main.async { [weak self] in
            self?.onCitiesChanged?(updatedCities)
        }
        return true
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return citiesLocal.count
    }

    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        indexPath.item < citiesLocal.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        moveItemAt sourceIndexPath: IndexPath,
        to destinationIndexPath: IndexPath
    ) {
        guard sourceIndexPath.item != destinationIndexPath.item else { return }
        guard
            citiesLocal.indices.contains(sourceIndexPath.item),
            destinationIndexPath.item >= 0,
            destinationIndexPath.item <= citiesLocal.count - 1
        else {
            return
        }

        // Collection indices are row-major in Cards, just as they are ordered
        // rows in Basic/Compact. The first item in this shared order is Primary.
        let movedCity = citiesLocal.remove(at: sourceIndexPath.item)
        citiesLocal.insert(movedCity, at: destinationIndexPath.item)

        #if DEBUG
        print("[REORDER_UIKIT] move from=\(sourceIndexPath.item) to=\(destinationIndexPath.item)")
        #endif

        let updatedCities = citiesLocal
        DispatchQueue.main.async { [weak self] in
            self?.onCitiesChanged?(updatedCities)
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CityListReorderCollectionCell.reuseIdentifier,
                for: indexPath
            ) as? CityListReorderCollectionCell
        else {
            return UICollectionViewCell()
        }

        guard indexPath.item < citiesLocal.count else { return cell }

        let city = citiesLocal[indexPath.item]
        let referenceTimeZone = citiesLocal.primaryCity?.timeZone ?? city.timeZone
        let matchedCurrentLocationIndex = currentLocationMatchIndex()
        cell.configure(
            city: city,
            selectedInstant: selectedInstant,
            referenceTimeZone: referenceTimeZone,
            isCurrent: city.id == citiesLocal.primaryCity?.id,
            isUserCurrentLocation: matchedCurrentLocationIndex == indexPath.item,
            cityViewPreference: cityViewPreference,
            cardBackgroundColor: cardBackgroundColor,
            isDuoPresentation: duoViewport != nil,
            cardTheme: cityViewPreference == .cards ? cardTheme : nil,
            showsActions: openActionsCityID == city.id,
            onRename: { [weak self] in self?.renameCity(id: city.id) },
            onDelete: { [weak self] in self?.deleteCity(id: city.id) },
            onOpenDetails: { [weak self] in self?.selectCity(id: city.id) }
        )
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !isReordering else { return }
        guard !isTapToOpenSuppressed else { return }
        guard citiesLocal.indices.contains(indexPath.item) else { return }

        if openActionsCityID != nil {
            setOpenActionsCityID(nil)
            return
        }
        let city = citiesLocal[indexPath.item]
        let haptics = UIImpactFeedbackGenerator(style: .light)
        haptics.impactOccurred()
        collectionView.deselectItem(at: indexPath, animated: true)

        DispatchQueue.main.async { [weak self] in
            self?.onCitySelected?(city)
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let height: CGFloat = cityViewPreference == .cards ? 200 : (cityViewPreference == .compact ? 88 : 140)
        return CGSize(width: max(0, collectionView.bounds.width - 32), height: height)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        8
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        CGSize(
            width: max(0, collectionView.bounds.width - 32),
            height: topInset + Self.logoHeight + (duoViewport == nil ? Self.logoBottomSpacing : 24)
        )
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }
        guard let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: Self.logoHeaderReuseIdentifier,
            for: indexPath
        ) as? CityListLogoHeaderView else {
            return UICollectionReusableView()
        }

        header.configure(
            topInset: topInset,
            logoHeight: Self.logoHeight,
            logoWidth: Self.logoWidth,
            logoBottomSpacing: duoViewport == nil ? Self.logoBottomSpacing : 24,
            duoAlignment: duoViewport != nil,
            isGrid: cityViewPreference == .cards
        )

        return header
    }
}

private extension City {
    var isZeroOffsetReferenceCity: Bool {
        CustomReferenceOffsetOption.from(canonicalID: id) != nil ||
            CustomReferenceOffsetOption.from(timeZoneIdentifier: timeZoneID) != nil
    }
}

private final class CityListLogoHeaderView: UICollectionReusableView {
    private let imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "HoursLogo"))
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        imageView.isUserInteractionEnabled = false
        return imageView
    }()

    private var topConstraint: NSLayoutConstraint?
    private var heightConstraint: NSLayoutConstraint?
    private var widthConstraint: NSLayoutConstraint?
    private var bottomConstraint: NSLayoutConstraint?
    private var centerXConstraint: NSLayoutConstraint?
    private var duoAlignment = false
    private var isGrid = false

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        guard duoAlignment else { return super.preferredLayoutAttributesFitting(layoutAttributes) }
        let attributes = layoutAttributes.copy() as! UICollectionViewLayoutAttributes
        attributes.size.height = 64
        return attributes
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        let topConstraint = imageView.topAnchor.constraint(equalTo: topAnchor)
        let heightConstraint = imageView.heightAnchor.constraint(equalToConstant: 15)
        let widthConstraint = imageView.widthAnchor.constraint(equalToConstant: 49)
        let bottomConstraint = bottomAnchor.constraint(greaterThanOrEqualTo: imageView.bottomAnchor)
        let centerXConstraint = imageView.centerXAnchor.constraint(equalTo: centerXAnchor)
        NSLayoutConstraint.activate([
            topConstraint,
            heightConstraint,
            widthConstraint,
            bottomConstraint,
            centerXConstraint
        ])

        self.topConstraint = topConstraint
        self.heightConstraint = heightConstraint
        self.widthConstraint = widthConstraint
        self.bottomConstraint = bottomConstraint
        self.centerXConstraint = centerXConstraint
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        if isGrid {
            if centerXConstraint?.constant != 0 { centerXConstraint?.constant = 0 }
        } else if duoAlignment {
            if centerXConstraint?.constant != 3 { centerXConstraint?.constant = 3 }
        } else if let collectionView = superview as? UICollectionView,
           let cell = collectionView.visibleCells.first {
            let cellFrame = cell.contentView.convert(cell.contentView.bounds, to: collectionView)
            let safeFrame = collectionView.safeAreaLayoutGuide.layoutFrame
            let leading = max(cellFrame.minX, safeFrame.minX)
            let trailing = min(cellFrame.maxX, safeFrame.maxX)
            if trailing > leading {
                let center = convert(CGPoint(x: (leading + trailing) / 2, y: cellFrame.midY), from: collectionView)
                centerXConstraint?.constant = center.x - bounds.midX
            }
        }
        super.layoutSubviews()
    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        setNeedsLayout()
    }

    func configure(topInset: CGFloat, logoHeight: CGFloat, logoWidth: CGFloat, logoBottomSpacing: CGFloat, duoAlignment: Bool = false, isGrid: Bool = false) {
        self.duoAlignment = duoAlignment
        self.isGrid = isGrid
        topConstraint?.constant = topInset
        heightConstraint?.constant = logoHeight
        widthConstraint?.constant = logoWidth
        bottomConstraint?.constant = logoBottomSpacing
    }
}

private final class CityListReorderCollectionCell: UICollectionViewCell {
    static let reuseIdentifier = "CityListReorderCollectionCell"
    private var duoCardHeight: CGFloat?
    private var usesResolvedPaneSafeArea = false
    private var openDetailsAccessibilityAction: (() -> Void)?
    fileprivate var actionPresentation = CardsActionPresentation()
    private var presentedCityID: City.ID?
    private var presentedStyle: CityViewPreference?

    override func accessibilityActivate() -> Bool {
        guard let action = openDetailsAccessibilityAction else { return super.accessibilityActivate() }
        action()
        return true
    }

    override var safeAreaInsets: UIEdgeInsets {
        // The Duo pane already resolves its safe area. Propagating the changing
        // display-edge inset into fixed-height hosted cards shifts their drawing
        // inside otherwise stationary cells as they cross the bottom edge.
        usesResolvedPaneSafeArea ? .zero : super.safeAreaInsets
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        if let duoCardHeight {
            let attributes = layoutAttributes.copy() as! UICollectionViewLayoutAttributes
            attributes.size.height = duoCardHeight
            return attributes
        }
        return super.preferredLayoutAttributesFitting(layoutAttributes)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        setLifted(false, animated: false)
        accessibilityCustomActions = nil
        openDetailsAccessibilityAction = nil
        accessibilityLabel = nil
        isAccessibilityElement = false
        contentView.accessibilityElementsHidden = false
        resetActionPresentation()
        presentedCityID = nil
        presentedStyle = nil
    }

    fileprivate func resetActionPresentation(open: Bool = false) {
        actionPresentation.invalidateCompletion()
        actionPresentation = CardsActionPresentation(open: open)
    }

    func configure(
        city: City,
        selectedInstant: Date,
        referenceTimeZone: TimeZone,
        isCurrent: Bool,
        isUserCurrentLocation: Bool,
        cityViewPreference: CityViewPreference,
        cardBackgroundColor: Color,
        isDuoPresentation: Bool = false,
        cardTheme: AppTheme? = nil,
        showsActions: Bool = false,
        onRename: @escaping () -> Void = {},
        onDelete: @escaping () -> Void = {},
        onOpenDetails: @escaping () -> Void = {}
    ) {
        if presentedCityID != city.id || presentedStyle != cityViewPreference {
            resetActionPresentation(open: cityViewPreference == .cards && showsActions)
            presentedCityID = city.id
            presentedStyle = cityViewPreference
        }
        let resolvesSafeArea = isDuoPresentation || cityViewPreference == .cards
        if usesResolvedPaneSafeArea != resolvesSafeArea {
            usesResolvedPaneSafeArea = resolvesSafeArea
            setNeedsLayout()
        }
        duoCardHeight = cityViewPreference == .cards ? 200 : (isDuoPresentation ? (cityViewPreference == .compact ? 88 : 140) : nil)
        let resolvedTheme = cardTheme ?? AppTheme.forColorScheme(traitCollection.userInterfaceStyle == .dark ? .dark : .light)
        let content = CityCardView(
            city: city,
            selectedInstant: selectedInstant,
            referenceTimeZone: referenceTimeZone,
            isCurrent: isCurrent,
            isUserCurrentLocation: isUserCurrentLocation,
            cityViewPreference: cityViewPreference,
            cardBackgroundColor: cardBackgroundColor,
            showsActions: showsActions,
            actionPresentation: cityViewPreference == .cards ? actionPresentation : nil,
            onRename: onRename,
            onDelete: onDelete,
            onOpenDetails: onOpenDetails
        )
        let isGrid = cityViewPreference == .cards
        isAccessibilityElement = isGrid
        contentView.accessibilityElementsHidden = isGrid
        accessibilityTraits = isGrid ? .button : []
        accessibilityLabel = isGrid ? content.accessibilitySummary : nil
        openDetailsAccessibilityAction = isGrid ? onOpenDetails : nil
        accessibilityCustomActions = isGrid ? [
            UIAccessibilityCustomAction(name: "Rename") { _ in onRename(); return true },
            UIAccessibilityCustomAction(name: "Delete") { _ in onDelete(); return true },
            UIAccessibilityCustomAction(name: "City Details") { _ in onOpenDetails(); return true }
        ] : nil
        contentConfiguration = UIHostingConfiguration {
            let card = content.environment(\.appTheme, resolvedTheme)
            if isDuoPresentation || cityViewPreference == .cards {
                card.ignoresSafeArea(.container)
            } else {
                card
            }
        }
        .margins(.all, 0)
    }

    func setLifted(_ lifted: Bool, animated: Bool = true) {
        let updates = {
            self.transform = lifted ? CGAffineTransform(scaleX: 1.03, y: 1.03) : .identity
            self.layer.shadowColor = UIColor.black.cgColor
            self.layer.shadowOpacity = lifted ? 0.18 : 0
            self.layer.shadowRadius = lifted ? 10 : 0
            self.layer.shadowOffset = lifted ? CGSize(width: 0, height: 6) : .zero
        }

        if animated {
            UIView.animate(
                withDuration: 0.16,
                delay: 0,
                options: [.beginFromCurrentState, .curveEaseOut],
                animations: updates
            )
        } else {
            updates()
        }
    }
}

@available(iOS 27.1, *)
private struct TrailingRegionControls<Horizontal: View, Settings: View, Add: View>: View {
    @Environment(\.toolbarVerticalEdge) private var toolbarEdge
    @Environment(\.layoutDirection) private var layoutDirection
    let geometry: GeometryProxy
    let contentFrame: CGRect
    let wheelFrame: CGRect
    let horizontal: Horizontal
    let settings: Settings
    let add: Add

    private var stackFrame: CGRect? {
        // Query physical coordinates; map the semantic toolbar edge explicitly for RTL.
        let isRightEdge = layoutDirection == .leftToRight ? toolbarEdge == .trailing : toolbarEdge == .leading
        guard isRightEdge else { return nil }
        let bounds = CGRect(origin: .zero, size: geometry.size)
        let origin = geometry.frame(in: .global).origin
        let content = contentFrame.offsetBy(dx: -origin.x, dy: -origin.y)
        let lane = CGRect(x: content.maxX, y: bounds.minY, width: bounds.maxX - content.maxX, height: bounds.height)
        guard lane.width >= 48, content.width > 0, bounds.contains(lane) else { return nil }
        let occlusions = geometry.reservedRegions(kind: .occlusion, layoutDirectionBehavior: .fixed)
        let divisions = geometry.reservedRegions(kind: .division, layoutDirectionBehavior: .fixed)
        // A nonzero inset alone is insufficient, including during initial attachment.
        guard occlusions.contains(where: {
            $0.frame.minX <= lane.minX && $0.frame.maxX >= lane.maxX &&
            $0.frame.minY <= bounds.minY && $0.frame.height > 0
        }) else { return nil }
        // ReservedRegion.frame already includes its interactive-content margins.
        let exclusions = (occlusions + divisions).map(\.frame)
        let top = exclusions.filter { $0.intersects(lane) }.map(\.maxY).max() ?? bounds.minY
        let frame = CGRect(x: lane.midX - 24, y: top + 12, width: 48, height: 108)
        guard bounds.contains(frame), frame.maxY <= content.maxY,
              !frame.intersects(content), !frame.intersects(wheelFrame),
              !exclusions.contains(where: { $0.intersects(frame) }) else { return nil }
        return frame
    }

    var body: some View {
        if let frame = stackFrame {
            GlassEffectContainer(spacing: 12) {
                VStack(spacing: 12) {
                    settings
                    add
                }
            }
            .position(x: frame.midX, y: frame.midY)
            .frame(width: geometry.size.width, height: geometry.size.height)
        } else {
            horizontal
        }
    }
}
