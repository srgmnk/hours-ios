import SwiftUI
import UIKit

/// A standalone map. The caller owns the viewport and the horizontal position's lifetime.
struct WorldMapView: View {
    /// Image coordinate at the viewport center in Figma: (634 + 393 / 2) / 1129.
    static let initialHorizontalPosition: CGFloat = (634 + 393 / 2) / 1129

    let viewportSize: CGSize
    /// Geographic image center within one longitude cycle, normalized to [0, 1).
    /// Initialize the binding to `initialHorizontalPosition` to match Figma.
    @Binding var horizontalPosition: CGFloat
    let cities: [City]
    let selectedInstant: Date

    @AppStorage(AppTimeFormatPreference.storageKey) private var timeFormatPreference = AppTimeFormatPreference.system.rawValue
    @Environment(\.locale) private var locale

    var body: some View {
        WorldMapScrollAdapter(
            horizontalPosition: $horizontalPosition,
            cities: cities,
            selectedInstant: selectedInstant,
            timeFormatPreference: timeFormatPreference,
            localeIdentifier: locale.identifier
        )
            .frame(
                width: viewportSize.width.isFinite ? max(0, viewportSize.width) : 0,
                height: viewportSize.height.isFinite ? max(0, viewportSize.height) : 0
            )
            .clipped()
    }
}

private struct WorldMapScrollAdapter: UIViewRepresentable {
    @Binding var horizontalPosition: CGFloat
    let cities: [City]
    let selectedInstant: Date
    let timeFormatPreference: String
    let localeIdentifier: String

    func makeUIView(context: Context) -> WorldMapScrollView {
        WorldMapScrollView()
    }

    static func dismantleUIView(_ view: WorldMapScrollView, coordinator: ()) {
        // Defer a final binding write out of SwiftUI's teardown transaction.
        view.publishPosition(deferred: true)
    }

    func updateUIView(_ view: WorldMapScrollView, context: Context) {
        view.updatePosition(horizontalPosition) { horizontalPosition = $0 }
        view.updateMarkers(cities, at: selectedInstant, timeFormatPreference: timeFormatPreference, localeIdentifier: localeIdentifier)
    }
}

private final class WorldMapScrollView: UIScrollView, UIScrollViewDelegate {
    // Image and markers occupy the same square, top-left-origin canvas.
    private let repeatedImage = WorldMapRepeatingView()
    private let repeatedCanvas = WorldMapRepeatingView()
    private let mapCanvas = UIView()
    private var markerAccessibility: [UIAccessibilityElement] = []
    private let imageView = UIImageView(image: UIImage(named: "worldmap"))
    private let coordinateResolver = LegacyCityCoordinateResolver()
    private var markers: [WorldMapMarkerView] = []
    private var sharedLabels: [WorldMapSharedLabelView] = []
    private var lastGroupingInputs: [WorldMapLabelGrouping.Input] = []
    private var lastGroupingViewport = CGSize.zero
    private var lastPlacementItems: [WorldMapLabelPlacement.Item] = []
    private var lastPlacementDots: [CGRect] = []
    private var lastPlacementScale: CGFloat = 0
    private var placementOffsets: [CGPoint] = []
    private var lastCities: [City] = []
    private var lastInstant: Date?
    private var lastTimeFormatPreference: String?
    private var lastLocaleIdentifier: String?
    private var normalizedCenter = WorldMapView.initialHorizontalPosition
    private var lastBindingPosition: CGFloat?
    private var lastViewportSize = CGSize.zero
    private var needsPositionUpdate = true
    private var isLayingOutMap = false
    private var positionChanged: ((CGFloat) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        delegate = self
        contentInsetAdjustmentBehavior = .never
        automaticallyAdjustsScrollIndicatorInsets = false
        bounces = false
        alwaysBounceHorizontal = false
        alwaysBounceVertical = false
        isDirectionalLockEnabled = true
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        minimumZoomScale = 1
        maximumZoomScale = 1
        pinchGestureRecognizer?.isEnabled = false
        // Geographic west/east must not mirror with the interface language.
        semanticContentAttribute = .forceLeftToRight
        clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.isAccessibilityElement = false
        // All backgrounds render behind all marker copies. Repeating the entire
        // opaque image/marker stack would paint over labels crossing the seam.
        addSubview(repeatedImage)
        repeatedImage.addSubview(imageView)
        addSubview(repeatedCanvas)
        repeatedCanvas.addSubview(mapCanvas)
        mapCanvas.accessibilityElementsHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updatePosition(_ position: CGFloat, onChange: @escaping (CGFloat) -> Void) {
        positionChanged = onChange
        let requested = position.isFinite
            ? WorldMapPeriodic.wrap(position, period: 1) : WorldMapView.initialHorizontalPosition
        guard lastBindingPosition != requested else { return }
        lastBindingPosition = requested
        normalizedCenter = requested
        needsPositionUpdate = true
        setNeedsLayout()
    }

    override func layoutSubviews() {
        guard !isLayingOutMap else { return }
        isLayingOutMap = true
        defer { isLayingOutMap = false }
        super.layoutSubviews()

        let viewport = bounds.size
        guard viewport.width > 0, viewport.height > 0,
              viewport.width.isFinite, viewport.height.isFinite else { return }
        if viewport != lastViewportSize || needsPositionUpdate {
            lastViewportSize = viewport
            needsPositionUpdate = false
            let scale = max(viewport.width / 393, viewport.height / 852)
            let side = 1129 * scale
            let canvasFrame = CGRect(x: 0, y: -13 * scale, width: 3 * side, height: side)
            repeatedImage.frame = canvasFrame
            repeatedCanvas.frame = canvasFrame
            repeatedImage.replicator.instanceCount = 3
            repeatedImage.replicator.instanceTransform = CATransform3DMakeTranslation(side, 0, 0)
            mapCanvas.frame = CGRect(x: 0, y: 0, width: side, height: side)
            imageView.frame = mapCanvas.bounds
            layoutMarkers()
            contentSize = CGSize(width: 3 * side, height: viewport.height)
            contentOffset = CGPoint(x: side + normalizedCenter * side - viewport.width / 2, y: 0)
        }
        recenterIfNecessary()
    }

    private func recenterIfNecessary() {
        let side = mapCanvas.bounds.width
        guard side > 0 else { return }
        let center = contentOffset.x + bounds.width / 2
        let cycles = floor(center / side) - 1
        if cycles != 0 {
            // Rebase the native scroll bounds during layout without animation or
            // restarting deceleration. Unlike setContentOffset, this retains the
            // fractional world width exactly instead of rounding to display pixels.
            bounds.origin = CGPoint(x: contentOffset.x - cycles * side, y: 0)
        }
        // didScroll records user motion. Keep the logical center during resizing;
        // reading UIKit’s pixel-rounded offset here would accumulate resize drift.
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isLayingOutMap, bounds.size == lastViewportSize,
              mapCanvas.bounds.width > 0 else { return }
        normalizedCenter = WorldMapPeriodic.wrap((contentOffset.x + bounds.width / 2) / mapCanvas.bounds.width, period: 1)
        // UIKit schedules layout during dragging/deceleration; no SwiftUI binding
        // writes or label layout are needed for individual scrolling frames.
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate { publishPosition() }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) { publishPosition() }
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) { publishPosition() }

    func publishPosition(deferred: Bool = false) {
        guard mapCanvas.bounds.width > 0, lastBindingPosition != normalizedCenter,
              let changed = positionChanged else { return }
        let position = normalizedCenter
        lastBindingPosition = position
        if deferred {
            DispatchQueue.main.async { changed(position) }
        } else {
            changed(position)
        }
    }

    override var accessibilityElements: [Any]? {
        get {
            let side = mapCanvas.bounds.width
            guard side > 0 else { return [] }
            let center = contentOffset.x + bounds.width / 2
            for (marker, element) in zip(markers, markerAccessibility) {
                let rectangle = marker.convert(marker.bounds, to: mapCanvas)
                let cycle = ((center - rectangle.midX) / side).rounded()
                element.accessibilityLabel = marker.accessibilityLabel
                element.accessibilityValue = marker.accessibilityValue
                element.accessibilityTraits = .staticText
                element.accessibilityFrameInContainerSpace = rectangle.offsetBy(dx: cycle * side, dy: repeatedCanvas.frame.minY)
            }
            return markerAccessibility
        }
        set { super.accessibilityElements = newValue }
    }

    func updateMarkers(_ cities: [City], at instant: Date, timeFormatPreference: String, localeIdentifier: String) {
        let citiesChanged = cities != lastCities
        guard citiesChanged || instant != lastInstant || timeFormatPreference != lastTimeFormatPreference ||
                localeIdentifier != lastLocaleIdentifier else { return }

        if citiesChanged {
            // Reuse views by saved identity, preserving input order and even repeated IDs.
            // Labels may be shared; every resolved city keeps its own marker and dot.
            var reusable = Dictionary(grouping: markers, by: \.cityID)
            markers = cities.compactMap { city in
                guard let coordinate = coordinateResolver.coordinate(for: city) else { return nil }
                let marker = reusable[city.id]?.popLast() ?? WorldMapMarkerView(cityID: city.id)
                marker.configure(city: city, point: WorldMapProjection.normalizedPoint(coordinate))
                mapCanvas.addSubview(marker)
                return marker
            }
            for marker in reusable.values.joined() { marker.removeFromSuperview() }
            lastCities = cities
            markerAccessibility = markers.map { _ in UIAccessibilityElement(accessibilityContainer: self) }
        }
        var labelsChanged = citiesChanged
        for marker in markers {
            if marker.updateTime(at: instant) { labelsChanged = true }
        }
        lastInstant = instant
        lastTimeFormatPreference = timeFormatPreference
        lastLocaleIdentifier = localeIdentifier
        if labelsChanged { layoutMarkers() }
    }

    private func layoutMarkers() {
        let side = mapCanvas.bounds.width
        guard side > 0 else { return }
        let scale = side / 1129
        for marker in markers {
            marker.transform = CGAffineTransform(scaleX: scale, y: scale)
            // The geographic anchor is the dot's center: (width / 2, 6) in the
            // 56-point-tall reference marker, rather than the text block's center.
            marker.center = CGPoint(x: marker.normalizedPoint.x * side,
                                    y: marker.normalizedPoint.y * side + 22 * scale)
        }
        layoutSharedLabels(scale: scale)
        layoutRepetition()
    }

    private func layoutRepetition() {
        let side = mapCanvas.bounds.width
        guard side > 0 else { return }
        var ink = mapCanvas.bounds
        for marker in markers {
            ink = ink.union(marker.convert(marker.indicatorBounds, to: mapCanvas))
            if !marker.labelsHidden { ink = ink.union(marker.convert(marker.placedLabelBounds, to: mapCanvas)) }
        }
        for view in sharedLabels { ink = ink.union(view.convert(view.labelBounds, to: mapCanvas)) }
        // Usually 0...2 (three cycles). Additional layer-only guards handle unusually
        // long labels without dropping their overhang when the camera rebases.
        let first = min(0, Int(ceil((side - bounds.width / 2 - ink.maxX) / side)))
        let last = max(2, Int(floor((2 * side + bounds.width / 2 - ink.minX) / side)))
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        mapCanvas.frame.origin.x = CGFloat(first) * side
        repeatedCanvas.replicator.instanceCount = last - first + 1
        repeatedCanvas.replicator.instanceTransform = CATransform3DMakeTranslation(side, 0, 0)
        CATransaction.commit()
    }

    private func layoutSharedLabels(scale: CGFloat) {
        let inputs = markers.map { marker in
            let point = CGPoint(x: marker.normalizedPoint.x * mapCanvas.bounds.width,
                                y: marker.normalizedPoint.y * mapCanvas.bounds.height)
            return WorldMapLabelGrouping.Input(
                cityID: marker.cityID, name: marker.displayName, time: marker.displayedTime,
                dotBounds: CGRect(x: point.x - 6 * scale, y: point.y - 6 * scale,
                                  width: 12 * scale, height: 12 * scale),
                labelBounds: marker.convert(marker.defaultLabelBounds, to: mapCanvas)
            )
        }
        // No contentOffset in this key: scrolling only translates the established canvas.
        guard inputs != lastGroupingInputs || bounds.size != lastGroupingViewport else { return }
        lastGroupingInputs = inputs
        lastGroupingViewport = bounds.size
        // The complete orange-dot footprint must fit inside one two-line text block.
        let groups = WorldMapLabelGrouping.groups(inputs, maximumSpan: 40 * scale, periodWidth: mapCanvas.bounds.width)
        for marker in markers { marker.setLabelsHidden(false) }
        while sharedLabels.count > groups.count { sharedLabels.removeLast().removeFromSuperview() }
        // 200 reference points accommodates two ordinary names; reserve the existing
        // 4-point gap at either viewport edge. Only shared names use this cap.
        let nameWidth = max(0, min(200, bounds.width / scale - 8))
        for (index, group) in groups.enumerated() {
            if index == sharedLabels.count {
                let label = WorldMapSharedLabelView()
                sharedLabels.append(label)
                mapCanvas.addSubview(label)
            }
            let names = group.map { markers[$0].displayName }
            let name = WorldMapLabelGrouping.sharedName(names, maximumWidth: nameWidth) {
                WorldMapMarkerView.label($0, size: 14).size().width
            }
            let label = sharedLabels[index]
            label.configure(name: name, time: inputs[group[0]].time)
            let footprint = WorldMapLabelGrouping.footprint(group, inputs: inputs, periodWidth: mapCanvas.bounds.width)
            label.transform = CGAffineTransform(scaleX: scale, y: scale)
            label.center = CGPoint(x: footprint.midX, y: footprint.maxY + (4 + 20) * scale)
            mapCanvas.bringSubviewToFront(label)
            for member in group { markers[member].setLabelsHidden(true) }
        }
        layoutLabelPlacement(groups: groups, inputs: inputs, scale: scale)
    }

    private enum LabelTarget {
        case marker(WorldMapMarkerView)
        case shared(WorldMapSharedLabelView)
    }

    private func layoutLabelPlacement(groups: [[Int]], inputs: [WorldMapLabelGrouping.Input], scale: CGFloat) {
        var units: [(item: WorldMapLabelPlacement.Item, target: LabelTarget)] = []
        let grouped = Set(groups.joined())
        for index in markers.indices where !grouped.contains(index) {
            units.append((.init(cityIDs: [markers[index].cityID], members: [index],
                                labelBounds: inputs[index].labelBounds, dotBounds: inputs[index].dotBounds),
                          .marker(markers[index])))
        }
        for (index, members) in groups.enumerated() {
            let view = sharedLabels[index]
            let dots = WorldMapLabelGrouping.footprint(members, inputs: inputs, periodWidth: mapCanvas.bounds.width)
            units.append((.init(cityIDs: members.map { markers[$0].cityID }, members: members,
                                labelBounds: view.convert(view.labelBounds, to: mapCanvas), dotBounds: dots),
                          .shared(view)))
        }
        units.sort { $0.item.members[0] < $1.item.members[0] }
        let items = units.map(\.item), dots = inputs.map(\.dotBounds)
        // Strings may change while measured ink and Stage 6A membership do not.
        // Reapply cached offsets after text sizing, without solving again.
        if items != lastPlacementItems || dots != lastPlacementDots || scale != lastPlacementScale {
            placementOffsets = WorldMapLabelPlacement.offsets(for: items, dots: dots, scale: scale, periodWidth: mapCanvas.bounds.width)
            lastPlacementItems = items
            lastPlacementDots = dots
            lastPlacementScale = scale
        }
        for (unit, offset) in zip(units, placementOffsets) {
            switch unit.target {
            case .marker(let marker):
                marker.setLabelOffset(CGPoint(x: offset.x / scale, y: offset.y / scale))
            case .shared(let view):
                view.center = CGPoint(x: view.center.x + offset.x, y: view.center.y + offset.y)
            }
        }
    }
}

private enum WorldMapProjection {
    static func normalizedPoint(_ coordinate: LocalCityCoordinates.Coordinate) -> CGPoint {
        let limit = 85.05112878
        let latitude = min(limit, max(-limit, coordinate.latitude)) * .pi / 180
        let x = (coordinate.longitude + 180) / 360
        let y = (1 - asinh(tan(latitude)) / .pi) / 2
        // Keep opposite longitude boundaries distinct; clamp floating-point roundoff.
        return CGPoint(x: min(1, max(0, x)), y: min(1, max(0, y)))
    }
}

private final class WorldMapMarkerView: UIView {
    let cityID: City.ID
    private(set) var normalizedPoint = CGPoint.zero
    private(set) var displayName = ""
    private(set) var displayedTime = ""
    private var timeZone = TimeZone(secondsFromGMT: 0)!
    private let indicator = UIImageView(image: UIImage(named: "worldmap-marker"))
    private let nameLabel = WorldMapMarkerLabel()
    private let timeLabel = WorldMapMarkerLabel()
    private var labelOffset = CGPoint.zero

    init(cityID: City.ID) {
        self.cityID = cityID
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        isAccessibilityElement = true
        accessibilityTraits = .staticText
        for label in [nameLabel, timeLabel] {
            label.textAlignment = .center
            label.isAccessibilityElement = false
        }
        addSubview(indicator)
        addSubview(nameLabel)
        addSubview(timeLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(city: City, point: CGPoint) {
        normalizedPoint = point
        timeZone = city.timeZone
        displayName = city.displayName
        nameLabel.attributedText = Self.label(displayName, size: 14)
        accessibilityLabel = displayName
        sizeLabels()
    }

    @discardableResult
    func updateTime(at instant: Date) -> Bool {
        let text = CityTimeFormatter.formatTime(instant, in: timeZone)
        guard text != displayedTime else { return false }
        displayedTime = text
        timeLabel.attributedText = Self.label(text, size: 18)
        accessibilityValue = text
        sizeLabels()
        return true
    }

    func setLabelsHidden(_ hidden: Bool) {
        nameLabel.isHidden = hidden
        timeLabel.isHidden = hidden
    }

    func setLabelOffset(_ offset: CGPoint) {
        let delta = CGPoint(x: offset.x - labelOffset.x, y: offset.y - labelOffset.y)
        nameLabel.frame = nameLabel.frame.offsetBy(dx: delta.x, dy: delta.y)
        timeLabel.frame = timeLabel.frame.offsetBy(dx: delta.x, dy: delta.y)
        labelOffset = offset
    }

    var indicatorBounds: CGRect { indicator.frame }
    var labelsHidden: Bool { nameLabel.isHidden }
    var placedLabelBounds: CGRect { defaultLabelBounds.offsetBy(dx: labelOffset.x, dy: labelOffset.y) }

    var defaultLabelBounds: CGRect {
        // Match the centered attributed-string drawing, including its 1-point outline.
        [nameLabel, timeLabel].enumerated().reduce(CGRect.null) { result, entry in
            let size = entry.element.attributedText?.size() ?? .zero
            return result.union(CGRect(x: bounds.midX - size.width / 2,
                                       y: CGFloat(26 + entry.offset * 20) - size.height / 2,
                                       width: size.width, height: size.height))
        }.insetBy(dx: -1, dy: -1)
    }

    private func sizeLabels() {
        let width = ceil(max(57, nameLabel.attributedText?.size().width ?? 0,
                             timeLabel.attributedText?.size().width ?? 0)) + 2
        bounds = CGRect(x: 0, y: 0, width: width, height: 56)
        // Figma's 32×32 export includes shadow padding; its 12-point dot starts at (10, 6).
        indicator.frame = CGRect(x: width / 2 - 16, y: -6, width: 32, height: 32)
        nameLabel.frame = CGRect(x: labelOffset.x, y: 16 + labelOffset.y, width: width, height: 20)
        timeLabel.frame = CGRect(x: labelOffset.x, y: 36 + labelOffset.y, width: width, height: 20)
    }

    static func label(_ text: String, size: CGFloat) -> NSAttributedString {
        // Figma: SF Pro Semibold, -4% tracking and black fill.
        NSAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: size, weight: .semibold),
            .kern: -0.04 * size,
            .foregroundColor: UIColor.black
        ])
    }
}


// Pure, bounded greedy grouping. Array order is saved-city order; member indices
// are transient layout references, never city or persistent group identities.
private enum WorldMapLabelGrouping {
    struct Input: Equatable {
        let cityID: City.ID
        let name: String
        let time: String
        let dotBounds: CGRect
        let labelBounds: CGRect
    }

    static func footprint(_ members: [Int], inputs: [Input], periodWidth: CGFloat) -> CGRect {
        members.dropFirst().reduce(inputs[members[0]].dotBounds) { bounds, member in
            bounds.union(WorldMapPeriodic.nearest(inputs[member].dotBounds, to: bounds.midX, period: periodWidth))
        }
    }

    static func groups(_ inputs: [Input], maximumSpan: CGFloat, periodWidth: CGFloat? = nil) -> [[Int]] {
        var groups: [[Int]] = []
        var footprints: [CGRect] = []
        var shifts = Array(repeating: CGFloat.zero, count: inputs.count)
        // The first member's saved position determines group priority; its existing
        // ID is the secondary tie-breaker. Saved positions are otherwise unique.
        for index in inputs.indices {
            let item = inputs[index]
            let candidate = groups.indices.lazy.filter { group in
                guard inputs[groups[group][0]].time == item.time else { return false }
                let dot = periodWidth.map { WorldMapPeriodic.nearest(item.dotBounds, to: footprints[group].midX, period: $0) } ?? item.dotBounds
                let shift = dot.minX - item.dotBounds.minX
                let footprint = footprints[group].union(dot)
                guard footprint.width <= maximumSpan, footprint.height <= maximumSpan else { return false }
                // Complete-link overlap prevents unrestricted connected-component chains.
                return groups[group].allSatisfy {
                    inputs[$0].labelBounds.offsetBy(dx: shifts[$0], dy: 0)
                        .intersects(item.labelBounds.offsetBy(dx: shift, dy: 0))
                }
            }.min { lhs, rhs in
                let a = groups[lhs][0], b = groups[rhs][0]
                return a == b ? inputs[a].cityID < inputs[b].cityID : a < b
            }
            if let candidate {
                let dot = periodWidth.map { WorldMapPeriodic.nearest(item.dotBounds, to: footprints[candidate].midX, period: $0) } ?? item.dotBounds
                shifts[index] = dot.minX - item.dotBounds.minX
                groups[candidate].append(index)
                footprints[candidate] = footprints[candidate].union(dot)
            } else {
                groups.append([index])
                footprints.append(item.dotBounds)
            }
        }
        return groups.filter { $0.count > 1 }
    }

    static func sharedName(_ names: [String], maximumWidth: CGFloat,
                           measure: (String) -> CGFloat) -> String {
        guard let first = names.first else { return "" }
        guard names.count > 1 else { return first }
        let remaining = names.count - 2
        let two = first + ", " + names[1] + (remaining > 0 ? " +\(remaining)" : "")
        if measure(two) <= maximumWidth { return two }
        let suffix = " +\(names.count - 1)"
        if measure(first + suffix) <= maximumWidth { return first + suffix }
        // Swift Character boundaries preserve composed accents and emoji sequences.
        let characters = Array(first)
        var lower = 0, upper = characters.count
        let width = max(maximumWidth, measure("…" + suffix))
        while lower < upper {
            let middle = (lower + upper + 1) / 2
            if measure(String(characters.prefix(middle)) + "…" + suffix) <= width {
                lower = middle
            } else {
                upper = middle - 1
            }
        }
        return String(characters.prefix(lower)) + "…" + suffix
    }
}

private final class WorldMapSharedLabelView: UIView {
    private let nameLabel = WorldMapMarkerLabel()
    private let timeLabel = WorldMapMarkerLabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        // Per-city marker accessibility retains every full name and local time.
        isAccessibilityElement = false
        for label in [nameLabel, timeLabel] {
            label.textAlignment = .center
            label.isAccessibilityElement = false
        }
        addSubview(nameLabel)
        addSubview(timeLabel)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    var labelBounds: CGRect {
        [nameLabel, timeLabel].reduce(CGRect.null) { result, label in
            let size = label.attributedText?.size() ?? .zero
            return result.union(CGRect(x: label.frame.midX - size.width / 2,
                                       y: label.frame.midY - size.height / 2,
                                       width: size.width, height: size.height))
        }.insetBy(dx: -1, dy: -1)
    }

    func configure(name: String, time: String) {
        nameLabel.attributedText = WorldMapMarkerView.label(name, size: 14)
        timeLabel.attributedText = WorldMapMarkerView.label(time, size: 18)
        let width = ceil(max(57, nameLabel.attributedText?.size().width ?? 0,
                             timeLabel.attributedText?.size().width ?? 0)) + 2
        bounds = CGRect(x: 0, y: 0, width: width, height: 40)
        nameLabel.frame = CGRect(x: 0, y: 0, width: width, height: 20)
        timeLabel.frame = CGRect(x: 0, y: 20, width: width, height: 20)
    }
}

private final class WorldMapMarkerLabel: UILabel {
    override func drawText(in rect: CGRect) {
        guard let text = attributedText, text.length > 0,
              let font = text.attribute(.font, at: 0, effectiveRange: nil) as? UIFont else { return }
        let size = text.size()
        let origin = CGPoint(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2)
        let outline = NSMutableAttributedString(attributedString: text)
        outline.addAttributes([
            .strokeColor: UIColor.white,
            .strokeWidth: 200 / font.pointSize
        ], range: NSRange(location: 0, length: text.length))
        // Paint the 2-point centered stroke first, then the fill, leaving Figma's
        // 1-point outer outline without covering the black glyphs.
        outline.draw(at: origin)
        text.draw(at: origin)
    }
}

/// Repeats one layer tree, sharing the image texture and all marker/text backing.
private final class WorldMapRepeatingView: UIView {
    override class var layerClass: AnyClass { CAReplicatorLayer.self }
    var replicator: CAReplicatorLayer { layer as! CAReplicatorLayer }
    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        isUserInteractionEnabled = false
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
