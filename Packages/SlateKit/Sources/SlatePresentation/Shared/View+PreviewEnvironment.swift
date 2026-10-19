import SwiftUI

extension View {

    func previewEnvironment() -> some View {
        inject(PresentationAssembly.preview())
    }
}
