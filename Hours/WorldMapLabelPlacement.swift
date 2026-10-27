import Foundation
import CoreGraphics

/// Pure geometry in rendered canvas points. No viewport origin or time text is
/// involved: equivalent geometry always produces the same placement.
enum WorldMapLabelPlacement {
    struct Item: Equatable {
        let cityIDs: [String]
        let members: [Int]
        let labelBounds: CGRect
        let dotBounds: CGRect
    }

    static func offsets(for items: [Item], dots: [CGRect], scale: CGFloat, periodWidth: CGFloat? = nil) -> [CGPoint] {
        guard !items.isEmpty, scale > 0 else { return [] }
        if items.count == 1, items[0].members.count == dots.count { return [.zero] }
        let gap = 4 * scale
        let clearance = 2 * scale
        let candidates = items.map { item -> [CGPoint] in
            let label = item.labelBounds, dot = item.dotBounds
            let above = dot.minY - gap - label.maxY
            let below = dot.maxY + gap - label.minY
            let left = dot.minX - gap - label.maxX
            let right = dot.maxX + gap - label.minX
            let centeredY = dot.midY - label.midY
            return [.zero,
                    CGPoint(x: dot.midX - label.midX, y: above),
                    CGPoint(x: left, y: centeredY), CGPoint(x: right, y: centeredY),
                    CGPoint(x: left, y: below), CGPoint(x: right, y: below),
                    CGPoint(x: left, y: above), CGPoint(x: right, y: above)]
        }
        let rectangles = items.indices.map { index in
            candidates[index].map { offset in
                items[index].labelBounds.offsetBy(dx: offset.x, dy: offset.y)
                    .insetBy(dx: -clearance, dy: -clearance)
            }
        }
        // Orange-dot bounds plus the existing two-point outside white outline.
        let dotRectangles = dots.map { $0.insetBy(dx: -2 * scale, dy: -2 * scale) }
        let order = items.indices.sorted { lhs, rhs in
            let a = items[lhs], b = items[rhs]
            if a.dotBounds.midY != b.dotBounds.midY { return a.dotBounds.midY < b.dotBounds.midY }
            let ax = periodWidth.map { WorldMapPeriodic.wrap(a.dotBounds.midX, period: $0) } ?? a.dotBounds.midX
            let bx = periodWidth.map { WorldMapPeriodic.wrap(b.dotBounds.midX, period: $0) } ?? b.dotBounds.midX
            if ax != bx { return ax < bx }
            if a.cityIDs != b.cityIDs { return a.cityIDs.lexicographicallyPrecedes(b.cityIDs) }
            return lhs < rhs
        }
        var choices = Array(repeating: 0, count: items.count)
        let areaScale = scale * scale
        // Two text-block heights per cell; this affects lookup work, never layout.
        let dotIndex = SpatialIndex(rectangles: dotRectangles, cellSize: 80 * scale)
        var labelIndex = SpatialIndex(rectangles: rectangles.map { $0[0] }, cellSize: 80 * scale)

        func overlap(_ a: CGRect, _ b: CGRect) -> CGFloat {
            let width = min(a.maxX, b.maxX) - max(a.minX, b.minX)
            guard width > 0 else { return 0 }
            let height = min(a.maxY, b.maxY) - max(a.minY, b.minY)
            return max(0, width * height) / areaScale
        }

        let dotExtent = dotRectangles.reduce(CGRect.null) { $0.union($1) }
        let labelExtent = rectangles.joined().reduce(CGRect.null) { $0.union($1) }
        func matches(_ index: SpatialIndex, rectangle: CGRect, extent: CGRect) -> [(Int, CGFloat)] {
            guard let period = periodWidth, period > 0 else {
                return index.indices(in: rectangle).map { ($0, 0) }
            }
            let first = Int(ceil((rectangle.minX - extent.maxX) / period))
            let last = Int(floor((rectangle.maxX - extent.minX) / period))
            guard first <= last else { return [] }
            var result: [(Int, CGFloat)] = []
            for cycle in first...last {
                let shift = CGFloat(cycle) * period
                for member in index.indices(in: rectangle.offsetBy(dx: -shift, dy: 0)) {
                    result.append((member, shift))
                }
            }
            return result
        }

        // Dots and candidate preferences are fixed throughout the optimization.
        let baseCosts = items.indices.map { index in
            let owned = Set(items[index].members)
            return candidates[index].indices.map { candidate -> CGFloat in
                let ink = rectangles[index][candidate].insetBy(dx: clearance, dy: clearance)
                var value: CGFloat = 0
                for (dot, shift) in matches(dotIndex, rectangle: ink, extent: dotExtent) where !owned.contains(dot) {
                    value += 8 * overlap(ink, dotRectangles[dot].offsetBy(dx: shift, dy: 0))
                }
                if candidate != 0 {
                    let offset = candidates[index][candidate]
                    value += 4 + CGFloat(candidate) * 0.01 + hypot(offset.x, offset.y) / scale * 0.01
                }
                return value
            }
        }

        func cost(_ index: Int, _ candidate: Int) -> CGFloat {
            let rectangle = rectangles[index][candidate]
            var result = baseCosts[index][candidate]
            for (other, shift) in matches(labelIndex, rectangle: rectangle, extent: labelExtent) where other != index {
                result += overlap(rectangle, rectangles[other][choices[other]].offsetBy(dx: shift, dy: 0))
            }
            return result
        }

        // Coordinate descent reduces one shared objective. Fixed forward/reverse
        // sweeps bound the work and avoid history-dependent or animated layouts.
        for pass in 0..<4 {
            var changed = false
            let indices = pass.isMultiple(of: 2) ? order : Array(order.reversed())
            for index in indices {
                var best = choices[index]
                var bestCost = cost(index, best)
                if bestCost == 0 { continue }
                for candidate in candidates[index].indices where candidate != best {
                    let value = cost(index, candidate)
                    if value < bestCost - 0.25 {
                        best = candidate
                        bestCost = value
                    }
                }
                if best != choices[index] {
                    labelIndex.remove(index, rectangle: rectangles[index][choices[index]])
                    choices[index] = best
                    labelIndex.insert(index, rectangle: rectangles[index][best])
                    changed = true
                }
            }
            if !changed { break }
        }
        return items.indices.map { candidates[$0][choices[$0]] }
    }

    private struct SpatialIndex {
        private struct Cell: Hashable { let x: Int; let y: Int }
        private let cellSize: CGFloat
        private var cells: [Cell: Set<Int>] = [:]

        init(rectangles: [CGRect], cellSize: CGFloat) {
            self.cellSize = cellSize
            for (index, rectangle) in rectangles.enumerated() { insert(index, rectangle: rectangle) }
        }

        mutating func insert(_ index: Int, rectangle: CGRect) {
            for cell in coveredCells(rectangle) { cells[cell, default: []].insert(index) }
        }

        mutating func remove(_ index: Int, rectangle: CGRect) {
            for cell in coveredCells(rectangle) {
                cells[cell]?.remove(index)
                if cells[cell]?.isEmpty == true { cells.removeValue(forKey: cell) }
            }
        }

        func indices(in rectangle: CGRect) -> [Int] {
            var result = Set<Int>()
            for cell in coveredCells(rectangle) {
                if let members = cells[cell] { result.formUnion(members) }
            }
            // Set/dictionary iteration order must never affect score accumulation.
            return result.sorted()
        }

        private func coveredCells(_ rectangle: CGRect) -> [Cell] {
            guard !rectangle.isEmpty, !rectangle.isNull else { return [] }
            let left = Int(floor(rectangle.minX / cellSize)), right = Int(floor(rectangle.maxX / cellSize))
            let top = Int(floor(rectangle.minY / cellSize)), bottom = Int(floor(rectangle.maxY / cellSize))
            var result: [Cell] = []
            for y in top...bottom {
                for x in left...right { result.append(Cell(x: x, y: y)) }
            }
            return result
        }
    }

}

/// Display-only longitude arithmetic; saved coordinates and identities are unchanged.
enum WorldMapPeriodic {
    static func wrap(_ value: CGFloat, period: CGFloat) -> CGFloat {
        let result = value.truncatingRemainder(dividingBy: period)
        return result < 0 ? result + period : result
    }
    static func nearest(_ rectangle: CGRect, to x: CGFloat, period: CGFloat) -> CGRect {
        rectangle.offsetBy(dx: ((x - rectangle.midX) / period).rounded() * period, dy: 0)
    }
}
