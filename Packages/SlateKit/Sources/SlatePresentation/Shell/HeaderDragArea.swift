import SwiftUI

struct HeaderDragArea: View {
    var body: some View {
        WindowDragArea(
            onMoved: { _ in },
            onDoubleClick: { NSApp.keyWindow?.performZoom(nil) }
        )
    }
}
