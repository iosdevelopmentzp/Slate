import SwiftUI

extension View {

    func previewEnvironment(surface: Surface = .panel) -> some View {
        inject(PresentationAssembly.preview())
            .environment(\.surface, surface)
    }
}
