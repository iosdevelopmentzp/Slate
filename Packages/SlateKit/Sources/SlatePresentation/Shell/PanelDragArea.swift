import SwiftUI

struct PanelDragArea: View {
    @Environment(WindowLayout.self) private var layout
    @Environment(\.surface) private var surface

    var body: some View {
        WindowDragArea(
            onMoved: { window in
                guard surface == .panel else { return }
                layout.panelTopLeft = CGPoint(x: window.frame.minX, y: window.frame.maxY)
                layout.fit(window)
            },
            onDoubleClick: {
                guard surface == .panel else { return }
                layout.panelTopLeft = nil
            }
        )
    }
}
