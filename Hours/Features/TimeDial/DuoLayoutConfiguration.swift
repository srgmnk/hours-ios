import SwiftUI
import UIKit

/// Capability is latched for this screen's lifetime. A transient nil hinge during
/// a display handoff must not remount the conventional screen.
struct DuoHingeState: Equatable {
    enum Status: Equatable { case unavailable, closed, partiallyOpen, fullyOpen }
    private(set) var isConfirmed = false
    private(set) var status: Status = .unavailable

    mutating func receive(_ status: Status) {
        if status != .unavailable { isConfirmed = true }
        self.status = status
    }
}

/// Pure presentation resolver. Geometry never establishes device capability.
struct DuoLayoutConfiguration: Equatable {
    enum Arrangement: Equatable { case conventional, outer, inner }
    struct Input {
        var hinge: DuoHingeState
        var bounds: CGRect
        var safeContent: CGRect
        var railOnRight: Bool?
        var occlusions: [CGRect]
        var divisions: [CGRect]
    }

    var arrangement: Arrangement
    var isTransition: Bool
    var content: CGRect
    var map: CGRect
    var list: CGRect
    var rail: CGRect
    var controls: CGRect?
    var bottomInset: CGFloat = 0
    private var containerBounds: CGRect? = nil
    private var usesEqualPanels = false
    private var mapContent: CGRect? = nil
    private var listContent: CGRect? = nil

    var isInner: Bool { arrangement == .inner }
    /// Retains a confirmed fully open presentation through transient nil hinge
    /// delivery, just like the pane geometry. Partial and single panes opt out.
    private(set) var usesCompactSettingsHeader = false
    /// Reuse the confirmed outer arrangement, including transient nil hinge delivery.
    /// Cropped fold panes must not place controls across a reserved region.
    var outerSwitcherFrame: CGRect? {
        guard arrangement == .outer, content.union(rail) == containerBounds,
              let controls else { return nil }
        let frame = CGRect(x: controls.minX,
                           y: rail.maxY - max(bottomInset, 24) - 48,
                           width: 48, height: 48)
        guard rail.contains(frame), frame.minY >= controls.maxY else { return nil }
        return frame
    }
    /// Interaction clearance is separate from the painted pane allocation.
    var mapViewport: CGRect { mapContent ?? map }
    var listViewport: CGRect { listContent ?? list }
    var wheelCenter: CGPoint {
        CGPoint(x: map.midX, y: map.maxY + (isInner ? 146 : 126))
    }
    // Preserve the approved outer overhang only at a settled endpoint. During a
    // fold, `mapViewport` is the safe pane and contains every visible wheel pixel.
    var wheelClip: CGRect { isInner || isTransition ? mapViewport : content.union(rail) }
    /// A confirmed Duo single pane may paint beneath its adjacent system rail.
    /// Hinge delivery can temporarily be unavailable even with valid outer
    /// geometry; do not make decorative coverage depend on that delivery timing.
    /// Cropped panes during an active fold never bridge the excluded region.
    var mapDrawingFrame: CGRect {
        if isInner { return usesEqualPanels ? map : mapViewport }
        guard arrangement == .outer, rail.width > 0,
              content.minY == rail.minY, content.maxY == rail.maxY,
              content.maxX == rail.minX || content.minX == rail.maxX,
              content.union(rail) == containerBounds else { return map }
        return content.union(rail)
    }
    var mapVisualViewport: CGRect? {
        guard mapDrawingFrame != mapViewport else { return nil }
        return mapDrawingFrame.offsetBy(dx: -mapViewport.minX, dy: -mapViewport.minY)
    }
    var blurHeight: CGFloat { isInner ? 95 : 140 }
    var blurFrame: CGRect {
        CGRect(x: mapDrawingFrame.minX - (isInner || isTransition ? 0 : 5), y: map.maxY - blurHeight,
               width: mapDrawingFrame.width + (isInner || isTransition ? 0 : 11), height: blurHeight)
    }

    static func resolve(_ input: Input, previous: Self? = nil) -> Self {
        let bounds = input.bounds
        guard input.hinge.isConfirmed else {
            return Self(arrangement: .conventional, isTransition: false, content: bounds,
                        map: bounds, list: bounds, rail: .zero, controls: nil)
        }
        guard bounds.width > 0, bounds.height > 0,
              bounds.width.isFinite, bounds.height.isFinite else {
            if var previous {
                previous.isTransition = true
                previous.usesCompactSettingsHeader = false
                return previous
            }
            return Self(arrangement: .outer, isTransition: true, content: .zero,
                        map: .zero, list: .zero, rail: .zero, controls: nil)
        }
        let right = input.railOnRight ?? (previous.map { $0.rail.midX >= $0.content.midX } ?? true)
        let measuredWidth = right ? bounds.maxX - input.safeContent.maxX : input.safeContent.minX - bounds.minX
        // The leading Split View rail has no status area, so iOS can report
        // zero safe inset. Prefer the measured rail retained across the move;
        // on first attachment use the same 24 + 48 + 12 control composition.
        let fallbackWidth = input.railOnRight == false
            ? (previous.flatMap { $0.rail.width >= 48 ? $0.rail.width : nil } ?? 24 + 48 + 12)
            : (previous?.rail.width ?? 0)
        let railWidth = measuredWidth >= 48 ? min(measuredWidth, bounds.width) : min(fallbackWidth, bounds.width)
        let rail = CGRect(x: right ? bounds.maxX - railWidth : bounds.minX,
                          y: bounds.minY, width: railWidth, height: bounds.height)
        var content = CGRect(x: right ? bounds.minX : rail.maxX, y: bounds.minY,
                             width: max(0, bounds.width - railWidth), height: bounds.height)
        let exclusions = (input.occlusions + input.divisions).filter { $0.intersects(bounds) }
        // A confirmed partial hinge uses the same inner presentation at its
        // available size. Retain its proportions across missing hinge delivery.
        let partiallyOpen = input.hinge.status == .partiallyOpen
        let equalPanels = partiallyOpen ||
            (input.hinge.status != .fullyOpen && previous?.usesEqualPanels == true)
        let acceptsPartialSize = partiallyOpen ||
            (input.hinge.status == .unavailable && previous?.usesEqualPanels == true)
        let canSplit = content.width > 0 && content.height > 0 &&
            (acceptsPartialSize || (content.width >= 740 && content.height >= 400)) &&
            (equalPanels || !exclusions.contains { $0.intersects(content.insetBy(dx: 0.5, dy: 0.5)) })
        // Hinge status can arrive before the window resize. Keep the previous
        // safe split until the narrow container actually arrives, even if the
        // hinge has already reported closed.
        let wantsInner = partiallyOpen || input.hinge.status == .fullyOpen || previous?.isInner == true
        var inner = wantsInner && canSplit
        // Figma 697:11041 splits the whole canvas: the right half includes
        // the existing system rail. Do not subtract that rail before halving.
        let splitX = min(content.maxX, max(content.minX, bounds.midX))
        var mapContent: CGRect?
        var listContent: CGRect?
        if inner && equalPanels {
            let left = CGRect(x: content.minX, y: content.minY, width: splitX - content.minX, height: content.height)
            let right = CGRect(x: left.maxX, y: content.minY, width: content.maxX - splitX, height: content.height)
            let safeMap = safePane(in: left, excluding: exclusions)
            // Division regions include touch margins, not an opaque visual gap.
            // Keep the list flush with the divider, clear of actual occlusions.
            let safeList = safePane(in: right, excluding: input.occlusions)
            // Preserve map/wheel interaction clearance while their decorative
            // content paints to the divider through the existing drawing viewport.
            inner = !safeMap.isEmpty && !safeList.isEmpty &&
                !input.occlusions.contains { $0.intersects(safeMap) || $0.intersects(safeList) }
            if inner { mapContent = safeMap; listContent = safeList }
        }
        if !inner {
            content = safePane(in: content, excluding: exclusions)
        }
        // Fully open keeps its approved 340pt list. Only the partial split is
        // centered on the full canvas, with the rail inside its existing half.
        let listWidth: CGFloat = inner ? (equalPanels ? content.maxX - splitX : 340) : content.width
        let list = CGRect(x: inner ? content.maxX - listWidth : content.minX,
                          y: content.minY, width: listWidth, height: content.height)
        let map = inner ? CGRect(x: content.minX, y: content.minY, width: content.width - listWidth, height: content.height) : content
        // The design leaves 12pt at the content side and 24pt at the outside of
        // its 84pt rail. Vertical placement starts after the system's reserved
        // frame, including its interactive margin.
        var controls: CGRect?
        let hasTopOcclusion = input.occlusions.contains {
            $0.minY <= bounds.minY && $0.intersection(rail).width >= rail.width - 1
        }
        let leadingSinglePane = input.railOnRight == false && !inner && content.union(rail) == bounds
        if rail.width >= 48, input.railOnRight != nil, hasTopOcclusion || leadingSinglePane {
            let x = right ? rail.minX + min(12, (rail.width - 48) / 2) : rail.maxX - 48 - min(12, (rail.width - 48) / 2)
            var y = bounds.minY + (hasTopOcclusion ? 0 : 24)
            for region in exclusions.filter({ $0.intersects(rail) }).sorted(by: { $0.minY < $1.minY }) {
                let candidate = CGRect(x: x, y: y, width: 48, height: 106)
                if candidate.intersects(region) { y = region.maxY }
            }
            let frame = CGRect(x: x, y: y, width: 48, height: 106)
            if bounds.contains(frame), !exclusions.contains(where: { $0.intersects(frame) }) { controls = frame }
        }
        let endpoint = (input.hinge.status == .closed && content.width < 740) ||
            ((input.hinge.status == .fullyOpen || partiallyOpen) && inner)
        return Self(arrangement: inner ? .inner : .outer, isTransition: !endpoint,
                    content: content, map: map, list: list, rail: rail, controls: controls,
                    bottomInset: max(0, bounds.maxY - input.safeContent.maxY), containerBounds: bounds,
                    usesEqualPanels: inner && equalPanels, mapContent: mapContent, listContent: listContent,
                    usesCompactSettingsHeader: inner && !equalPanels &&
                        (input.hinge.status == .fullyOpen ||
                         (input.hinge.status == .unavailable && previous?.usesCompactSettingsHeader == true)))
    }

    /// Reserved frames already include interactive margins. Reuse the existing
    /// safe-pane selection for each partial panel and for single-pane handoffs.
    private static func safePane(in frame: CGRect, excluding regions: [CGRect]) -> CGRect {
        var pane = frame
        for region in regions where region.intersects(pane) {
            let clipped = region.intersection(pane)
            if clipped.height >= pane.height / 2 {
                let left = CGRect(x: pane.minX, y: pane.minY, width: max(0, clipped.minX - pane.minX), height: pane.height)
                let right = CGRect(x: clipped.maxX, y: pane.minY, width: max(0, pane.maxX - clipped.maxX), height: pane.height)
                pane = right.width >= left.width ? right : left
            } else if clipped.minY <= pane.midY {
                pane = CGRect(x: pane.minX, y: clipped.maxY, width: pane.width, height: max(0, pane.maxY - clipped.maxY))
            }
        }
        return pane
    }
}

/// A zero-size observer bootstraps the initial capability as well as changes.
/// UIHingeInteraction delivers an initial context when attached to a window.
struct DuoHingeObserver: UIViewRepresentable {
    var changed: (DuoHingeState.Status) -> Void
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        if #available(iOS 27.1, *) {
            view.addInteraction(UIHingeInteraction { _, context in
                let status: DuoHingeState.Status
                switch context.hinge?.status {
                case .closed: status = .closed
                case .partiallyOpen: status = .partiallyOpen
                case .fullyOpen: status = .fullyOpen
                default: status = .unavailable
                }
                DispatchQueue.main.async { changed(status) }
            })
        }
        return view
    }
    func updateUIView(_ view: UIView, context: Context) {}
}

/// Measures below the safe-area boundary, but places content in full container
/// coordinates. Both endpoint arrangements use the same child view identities.
@available(iOS 27.1, *)
struct DuoLayoutContainer<Content: View>: View {
    @Environment(\.toolbarVerticalEdge) private var toolbarEdge
    @Environment(\.layoutDirection) private var direction
    let hinge: DuoHingeState
    @ViewBuilder var content: (DuoLayoutConfiguration, GeometryProxy) -> Content
    @State private var previous: DuoLayoutConfiguration?

    var body: some View {
        GeometryReader { safe in
            GeometryReader { geometry in
                let origin = geometry.frame(in: .global).origin
                let safeFrame = safe.frame(in: .global).offsetBy(dx: -origin.x, dy: -origin.y)
                let right = toolbarEdge.map { direction == .leftToRight ? $0 == .trailing : $0 == .leading }
                let configuration = DuoLayoutConfiguration.resolve(.init(
                    hinge: hinge, bounds: CGRect(origin: .zero, size: geometry.size),
                    safeContent: safeFrame, railOnRight: right,
                    occlusions: geometry.reservedRegions(kind: .occlusion, layoutDirectionBehavior: .fixed).map(\.frame),
                    divisions: geometry.reservedRegions(kind: .division, layoutDirectionBehavior: .fixed).map(\.frame)
                ), previous: previous)
                content(configuration, geometry)
                    .onChange(of: configuration, initial: true) { _, value in
                        if previous != value { previous = value }
                    }
            }
            .ignoresSafeArea()
        }
    }
}
