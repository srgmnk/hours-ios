import SwiftUI
import UIKit
import Combine

struct TimeDialScreen: View {
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
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appTheme) private var theme
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
                    SheetStyle.appScreenBackground(for: theme)
                        .ignoresSafeArea()

                    Group {
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
                            CityListReorderUIKitView(
                                cities: $cityStore.cities,
                                selectedInstant: selectedInstant,
                                userCurrentLocationItem: currentLocationProvider.currentCityItem,
                                cityViewPreference: selectedCityViewPreference,
                                // Keep scroll content layout independent from pinned button offset.
                                topSafeAreaInset: topButtonBarTopPadding + ((topButtonBarHeight - logoHeight) / 2),
                                // Desired visual stop gap from physical screen bottom.
                                bottomContentInset: cityListDesiredBottomGap,
                                cardBackgroundColor: SheetStyle.appCardBackground(for: theme),
                                onRenameRequested: presentRenameSheet(for:),
                                onCitySelected: presentCityDetails(for:)
                            )
                            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                        }
                    }
                    .id(isCitiesEmpty ? "empty" : "list")
                    .zIndex(isCitiesEmpty ? 1 : 0)

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
        .id("\(cityStore.cities.isEmpty ? "empty" : "list")-\(colorScheme == .dark ? "dark" : "light")")
        .ignoresSafeArea()
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
        }) {
            SettingsSheetView()
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

    private func addButton(iconOnly: Bool) -> some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            sheetsAwaitingDismissal.insert(.addCity)
            isAddCitySheetPresented = true
        }) {
            HStack(spacing: 4) {
                Image(systemName: "plus.capsule.fill")
                    .font(.system(size: 16, weight: .medium))
                if !iconOnly {
                    Text("Add")
                        .font(.system(size: 16, weight: .medium))
                        .tracking(-0.64)
                }
            }
            .foregroundStyle(theme.textPrimary.opacity(0.90))
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
                .foregroundStyle(theme.textPrimary.opacity(0.90))
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

    private func presentCityDetails(for city: City) {
        sheetsAwaitingDismissal.insert(.cityDetails)
        cityDetailsPresentation = CityDetailsPresentation(
            city: city,
            primaryCity: cityStore.cities.first ?? city,
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

private struct CityListReorderUIKitView: UIViewControllerRepresentable {
    @Binding var cities: [City]
    let selectedInstant: Date
    let userCurrentLocationItem: CitySearchItem?
    let cityViewPreference: CityViewPreference
    let topSafeAreaInset: CGFloat
    let bottomContentInset: CGFloat
    let cardBackgroundColor: Color
    let onRenameRequested: (City) -> Void
    let onCitySelected: (City) -> Void

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
        controller.apply(
            cities: cities,
            selectedInstant: selectedInstant,
            userCurrentLocationItem: userCurrentLocationItem,
            cityViewPreference: cityViewPreference,
            topInset: topSafeAreaInset,
            bottomInset: bottomContentInset,
            cardBackgroundColor: cardBackgroundColor
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: CityListReorderViewController, context: Context) {
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
        uiViewController.apply(
            cities: cities,
            selectedInstant: selectedInstant,
            userCurrentLocationItem: userCurrentLocationItem,
            cityViewPreference: cityViewPreference,
            topInset: topSafeAreaInset,
            bottomInset: bottomContentInset,
            cardBackgroundColor: cardBackgroundColor
        )
    }
}

private final class CityListReorderViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
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

        return UICollectionViewCompositionalLayout { _, layoutEnvironment in
            let section = NSCollectionLayoutSection.list(
                using: listConfiguration,
                layoutEnvironment: layoutEnvironment
            )
            section.interGroupSpacing = 8
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8)
            return section
        }
    }()
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
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

    private var citiesLocal: [City] = []
    private var selectedInstant: Date = Date()
    private var topInset: CGFloat = 0
    private var bottomInset: CGFloat = 0
    private var userCurrentLocationItem: CitySearchItem?
    private var cityViewPreference: CityViewPreference = .basic
    private var cardBackgroundColor: Color = AppTheme.light.surfaceCard
    private var isReordering = false
    private var isTapToOpenSuppressed = false
    private var pendingExternalState: PendingExternalState?
    private var needsPostAttachReload = false
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
        collectionView.addGestureRecognizer(longPressGestureRecognizer)
        applySectionInsets()
        deleteSuccessHaptics.prepare()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applySectionInsets()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        runPostAttachReloadIfNeeded()
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
        let safeBottom = collectionView.safeAreaInsets.bottom
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
            let referenceTimeZone = citiesLocal.first?.timeZone ?? city.timeZone
            cell.configure(
                city: city,
                selectedInstant: selectedInstant,
                referenceTimeZone: referenceTimeZone,
                isCurrent: indexPath.item == 0,
                isUserCurrentLocation: matchedCurrentLocationIndex == indexPath.item,
                cityViewPreference: cityViewPreference,
                cardBackgroundColor: cardBackgroundColor
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
            guard collectionView.beginInteractiveMovementForItem(at: indexPath) else { return }

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
            target.x = collectionView.bounds.midX
            collectionView.updateInteractiveMovementTargetPosition(target)

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

    private func finishInteractiveMovement() {
        isReordering = false
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
            cities: pendingExternalState.cities,
            selectedInstant: pendingExternalState.selectedInstant,
            userCurrentLocationItem: pendingExternalState.userCurrentLocationItem,
            cityViewPreference: pendingExternalState.cityViewPreference,
            topInset: pendingExternalState.topInset,
            bottomInset: pendingExternalState.bottomInset,
            cardBackgroundColor: pendingExternalState.cardBackgroundColor
        )
    }

    private func trailingSwipeActionsConfiguration(for indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !isReordering else { return nil }
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
            triggerRenameHaptics()
            let city = self.citiesLocal[indexPath.item]
            DispatchQueue.main.async {
                self.onRenameRequested?(city)
            }
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
        let referenceTimeZone = citiesLocal.first?.timeZone ?? city.timeZone
        let matchedCurrentLocationIndex = currentLocationMatchIndex()
        cell.configure(
            city: city,
            selectedInstant: selectedInstant,
            referenceTimeZone: referenceTimeZone,
            isCurrent: indexPath.item == 0,
            isUserCurrentLocation: matchedCurrentLocationIndex == indexPath.item,
            cityViewPreference: cityViewPreference,
            cardBackgroundColor: cardBackgroundColor
        )
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !isReordering else { return }
        guard !isTapToOpenSuppressed else { return }
        guard citiesLocal.indices.contains(indexPath.item) else { return }

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
        let height: CGFloat = cityViewPreference == .compact ? 88 : 140
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
            height: topInset + Self.logoHeight + Self.logoBottomSpacing
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
            logoBottomSpacing: Self.logoBottomSpacing
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
        if let collectionView = superview as? UICollectionView,
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

    func configure(topInset: CGFloat, logoHeight: CGFloat, logoWidth: CGFloat, logoBottomSpacing: CGFloat) {
        topConstraint?.constant = topInset
        heightConstraint?.constant = logoHeight
        widthConstraint?.constant = logoWidth
        bottomConstraint?.constant = logoBottomSpacing
    }
}

private final class CityListReorderCollectionCell: UICollectionViewCell {
    static let reuseIdentifier = "CityListReorderCollectionCell"

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
    }

    func configure(
        city: City,
        selectedInstant: Date,
        referenceTimeZone: TimeZone,
        isCurrent: Bool,
        isUserCurrentLocation: Bool,
        cityViewPreference: CityViewPreference,
        cardBackgroundColor: Color
    ) {
        let resolvedTheme = AppTheme.forColorScheme(traitCollection.userInterfaceStyle == .dark ? .dark : .light)
        contentConfiguration = UIHostingConfiguration {
            CityCardView(
                city: city,
                selectedInstant: selectedInstant,
                referenceTimeZone: referenceTimeZone,
                isCurrent: isCurrent,
                isUserCurrentLocation: isUserCurrentLocation,
                cityViewPreference: cityViewPreference,
                cardBackgroundColor: cardBackgroundColor
            )
            .environment(\.appTheme, resolvedTheme)
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
