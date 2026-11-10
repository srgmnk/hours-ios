import Foundation

enum WorldMapGeometryProfile: Equatable {
    case conventional
    case duoInner
    case duoInnerPortrait
    case duoOuter

    static let duoInitialCenter: CGFloat = (474 + 527 / 2) / 1022
    static let duoPortraitInitialCenter: CGFloat = (669 / 2 - 1) / 668

    // Keep the approved fully open crop as the geographic reference. A shared
    // Mercator Y means the same latitude even when canvas scales differ.
    private static let duoCenterY: CGFloat = {
        let viewport = CGSize(width: 527, height: 669)
        let reference = WorldMapGeometryProfile.duoInner.canvas(in: viewport)
        return (viewport.height / 2 - reference.top) / reference.side
    }()

    func canvas(in viewport: CGSize) -> (side: CGFloat, top: CGFloat) {
        switch self {
        case .conventional:
            // Preserve the production portrait geometry, including arithmetic order.
            let scale = max(viewport.width / 393, viewport.height / 852)
            return (1129 * scale, -13 * scale)
        case .duoOuter:
            let geometry = WorldMapGeometryProfile.conventional.canvas(in: viewport)
            return (geometry.side, viewport.height / 2 - Self.duoCenterY * geometry.side)
        case .duoInner:
            let scale = max(viewport.width / 527, viewport.height / 669)
            return (1022 * scale, -97 * scale)
        case .duoInnerPortrait:
            // Portrait-only refinement: uniform 10% artwork enlargement and a
            // 80-point upward refinement from the previous +40-point shift.
            // All geographic layers share this canvas; the panel and wheel stay fixed.
            let scale = max(viewport.width / 669, viewport.height / 476)
            return (668 * scale * 1.10, -53 * scale + 40 - 80)
        }
    }
}
