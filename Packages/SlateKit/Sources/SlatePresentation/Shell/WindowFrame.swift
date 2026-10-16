import SwiftUI
import SlateUI

struct WindowFrame: ViewModifier {
    let layout: WindowLayout
    let surface: Surface

    func body(content: Content) -> some View {
        switch surface {
        case .window:
            content
                .frame(
                    minWidth: WindowLayout.minimumSize.width,
                    idealWidth: layout.size.width,
                    maxWidth: .infinity,
                    minHeight: WindowLayout.minimumSize.height,
                    idealHeight: layout.size.height,
                    maxHeight: .infinity
                )
        case .panel:
            content
                .frame(width: layout.size.width, height: layout.size.height)
        }
    }
}
