import SwiftUI

enum SheetStyle {
    static func appScreenBackground(for theme: AppTheme) -> Color {
        theme.screenBackground
    }

    static func appCardBackground(for theme: AppTheme) -> Color {
        theme.surfaceCard
    }

    static func groupedRowBackground(for theme: AppTheme) -> Color {
        theme.surfaceGroupedRow
    }
}
