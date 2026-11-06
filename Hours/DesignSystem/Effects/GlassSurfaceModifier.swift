import SwiftUI

struct GlassSurfaceModifier<S: Shape>: ViewModifier {
    let shape: S

    func body(content: Content) -> some View {
        content
            .contentShape(shape)
            .glassEffect(.regular, in: shape)
    }
}
