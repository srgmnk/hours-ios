import SwiftUI
import UIKit

struct CityListRow: Identifiable, Equatable {
    let id: String
    let index: Int
    let cityName: String
    let timeZoneID: String
    let isCurrent: Bool
}

private struct RowFramePreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]

    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

struct CityReorderListView: View {
    @ObservedObject var viewModel: TimeDialViewModel
    let rows: [CityListRow]
    let onReorderStart: (String) -> Void
    let onMove: (Int, Int) -> Void
    let onDelete: (String) -> Void

    @State private var swipeOffsets: [String: CGFloat] = [:]
    @State private var swipeStates: [String: SwipeTrackingState] = [:]
    @State private var openSwipeID: String?
    @State private var activeDragID: String?
    @State private var activeDragOffset: CGFloat = 0
    @State private var rowFrames: [String: CGRect] = [:]
    @State private var collapsingID: String?

    private let deleteHaptics = UINotificationFeedbackGenerator()
    private let scrollSpaceName = "CityScrollSpace"
    private let rowHeight: CGFloat = 148
    private let deleteRevealWidth: CGFloat = 88
    private let collapseDuration: TimeInterval = 0.22
    private let defaultCardBackground = Color(red: 0xF7 / 255, green: 0xF7 / 255, blue: 0xF7 / 255)

    private enum SwipeIntent {
        case undecided
        case horizontal
        case vertical
    }

    private struct SwipeTrackingState {
        var intent: SwipeIntent
        var startOffset: CGFloat
    }

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(rows) { row in
                    rowView(row)
                }

                Color.clear
                    .frame(height: 220)
            }
        }
        .coordinateSpace(name: scrollSpaceName)
        .scrollIndicators(.hidden)
        .scrollDisabled(activeDragID != nil)
        .onPreferenceChange(RowFramePreferenceKey.self) { rowFrames = $0 }
        .onAppear { deleteHaptics.prepare() }
        .onChange(of: rows.map(\.id)) { _, newIDs in
            let idSet = Set(newIDs)
            swipeOffsets = swipeOffsets.filter { idSet.contains($0.key) }
            swipeStates = swipeStates.filter { idSet.contains($0.key) }
            if let openSwipeID, !idSet.contains(openSwipeID) {
                self.openSwipeID = nil
            }
            if let activeDragID, !idSet.contains(activeDragID) {
                self.activeDragID = nil
                activeDragOffset = 0
            }
            if let collapsingID, !idSet.contains(collapsingID) {
                self.collapsingID = nil
            }
        }
    }

    @ViewBuilder
    private func rowView(_ row: CityListRow) -> some View {
        let horizontalOffset = swipeOffsets[row.id] ?? 0
        let isSwiping = horizontalOffset < 0
        let isDragging = activeDragID == row.id
        let isCollapsing = collapsingID == row.id

        ZStack(alignment: .trailing) {
            if isSwiping && rows.count > 1 {
                HStack {
                    Spacer(minLength: 0)
                    DeleteButtonView {
                        handleDelete(row.id)
                    }
                    .padding(.trailing, 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            HStack {
                Spacer(minLength: 0)
                CityCardView(
                    viewModel: viewModel,
                    cityID: row.id,
                    cityName: row.cityName,
                    timeZoneID: row.timeZoneID,
                    cardBackgroundColor: isSwiping ? .white : defaultCardBackground
                )
                Spacer(minLength: 0)
            }
            .frame(height: 140)
            .padding(.bottom, 8)
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(
                            key: RowFramePreferenceKey.self,
                            value: [row.id: geo.frame(in: .named(scrollSpaceName))]
                        )
                }
            )
            .offset(x: horizontalOffset)
            .offset(y: isDragging ? activeDragOffset : 0)
            .scaleEffect(isDragging ? 1.01 : 1.0)
            .zIndex(isDragging ? 1000 : 0)
        }
        .frame(height: isCollapsing ? 0 : rowHeight, alignment: .top)
        .opacity(isCollapsing ? 0 : 1)
        .clipped()
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: collapseDuration), value: isCollapsing)
        .simultaneousGesture(swipeGesture(for: row.id))
        .simultaneousGesture(reorderGesture(for: row.id))
    }

    private func swipeGesture(for id: String) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard activeDragID == nil, collapsingID == nil, rows.count > 1 else { return }

                var state = swipeStates[id] ?? SwipeTrackingState(
                    intent: .undecided,
                    startOffset: swipeOffsets[id] ?? 0
                )

                let dx = value.translation.width
                let dy = value.translation.height

                if state.intent == .undecided {
                    if abs(dx) > abs(dy) + 8 {
                        state.intent = .horizontal
                    } else if abs(dy) > abs(dx) + 8 {
                        state.intent = .vertical
                    } else {
                        swipeStates[id] = state
                        return
                    }
                }

                if state.intent == .horizontal {
                    if let openSwipeID, openSwipeID != id {
                        closeOpenSwipe(animated: true)
                    }
                    let raw = state.startOffset + dx
                    swipeOffsets[id] = min(0, max(-deleteRevealWidth, raw))
                }

                swipeStates[id] = state
            }
            .onEnded { _ in
                guard activeDragID == nil else { return }
                let state = swipeStates[id] ?? SwipeTrackingState(
                    intent: .undecided,
                    startOffset: swipeOffsets[id] ?? 0
                )
                swipeStates[id] = nil

                guard state.intent == .horizontal else {
                    return
                }

                let currentOffset = swipeOffsets[id] ?? 0
                let shouldOpen = currentOffset <= -(deleteRevealWidth * 0.45)

                withAnimation(.interactiveSpring(response: 0.24, dampingFraction: 0.9)) {
                    if shouldOpen {
                        swipeOffsets[id] = -deleteRevealWidth
                        openSwipeID = id
                    } else {
                        swipeOffsets[id] = 0
                        if openSwipeID == id {
                            openSwipeID = nil
                        }
                    }
                }
            }
    }

    private func reorderGesture(for id: String) -> some Gesture {
        LongPressGesture(minimumDuration: 0.30)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .named(scrollSpaceName)))
            .onChanged { value in
                switch value {
                case .first(true):
                    beginDragging(id)
                case .second(true, let drag?):
                    beginDragging(id)
                    activeDragOffset = drag.translation.height
                    updateReorderTarget(for: id, translationY: drag.translation.height)
                default:
                    break
                }
            }
            .onEnded { _ in
                endDragging(id)
            }
    }

    private func beginDragging(_ id: String) {
        guard collapsingID == nil else { return }
        guard activeDragID == nil else { return }

        closeOpenSwipe(animated: true)
        activeDragID = id
        activeDragOffset = 0
        onReorderStart(id)
    }

    private func endDragging(_ id: String) {
        guard activeDragID == id else { return }
        withAnimation(.interactiveSpring(response: 0.24, dampingFraction: 0.9)) {
            activeDragOffset = 0
        }
        activeDragID = nil
    }

    private func updateReorderTarget(for draggingID: String, translationY: CGFloat) {
        guard activeDragID == draggingID else { return }
        guard let currentIndex = rows.firstIndex(where: { $0.id == draggingID }) else { return }
        guard let draggingFrame = rowFrames[draggingID] else { return }

        let draggedMidY = draggingFrame.midY + translationY
        let candidates = rows.compactMap { row -> (id: String, midY: CGFloat)? in
            guard let frame = rowFrames[row.id] else { return nil }
            return (row.id, frame.midY)
        }

        guard !candidates.isEmpty else { return }
        guard let nearestID = candidates.min(by: { abs($0.midY - draggedMidY) < abs($1.midY - draggedMidY) })?.id,
              let targetIndex = rows.firstIndex(where: { $0.id == nearestID }) else {
            return
        }

        guard targetIndex != currentIndex else { return }

        withAnimation(.interactiveSpring(response: 0.26, dampingFraction: 0.88)) {
            onMove(currentIndex, targetIndex)
        }
    }

    private func closeOpenSwipe(animated: Bool) {
        guard let openSwipeID else { return }
        if animated {
            withAnimation(.interactiveSpring(response: 0.24, dampingFraction: 0.9)) {
                swipeOffsets[openSwipeID] = 0
            }
        } else {
            swipeOffsets[openSwipeID] = 0
        }
        self.openSwipeID = nil
    }

    private func handleDelete(_ id: String) {
        guard rows.count > 1 else { return }
        guard collapsingID == nil else { return }

        closeOpenSwipe(animated: false)
        deleteHaptics.notificationOccurred(.error)
        deleteHaptics.prepare()

        withAnimation(.easeInOut(duration: collapseDuration)) {
            collapsingID = id
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + collapseDuration) {
            let noAnimation = Transaction(animation: nil)
            withTransaction(noAnimation) {
                onDelete(id)
            }
            collapsingID = nil
            swipeOffsets[id] = nil
            swipeStates[id] = nil
            if openSwipeID == id {
                openSwipeID = nil
            }
        }
    }
}
