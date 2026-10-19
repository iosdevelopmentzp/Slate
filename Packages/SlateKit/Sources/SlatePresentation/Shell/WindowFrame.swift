import SwiftUI
import SlateUI

struct WindowFrame: ViewModifier {
    let layout: WindowLayout

    func body(content: Content) -> some View {
        content
            .frame(
                minWidth: WindowLayout.minimumSize.width,
                idealWidth: layout.size.width,
                maxWidth: .infinity,
                minHeight: WindowLayout.minimumSize.height,
                idealHeight: layout.size.height,
                maxHeight: .infinity
            )
    }
}
