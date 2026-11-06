import SwiftUI

// Observe at the rendered leaf, below deferred geometry/build closures.
// Capturing a parent view's theme in those closures can retain an old palette.
struct AppScreenBackground: View {
    @Environment(\.appTheme) private var theme

    var body: some View {
        SheetStyle.appScreenBackground(for: theme)
    }
}

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
