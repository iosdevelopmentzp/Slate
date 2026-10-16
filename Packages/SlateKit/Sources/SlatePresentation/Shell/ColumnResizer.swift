import AppKit
import SwiftUI
import SlateUI

struct ColumnResizer: View {
    @Environment(WindowLayout.self) private var layout

    @State private var startWidth: CGFloat?

    var body: some View {
        Color.clear
            .frame(width: 8)
            .contentShape(Rectangle())
            .onHover { isHovered in
                if isHovered {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
            .gesture(
                DragGesture(minimumDistance: 1, coordinateSpace: .global)
                    .onChanged { value in
                        let start = startWidth ?? layout.listWidth
                        startWidth = start
                        layout.listWidth = WindowLayout.clampedListWidth(start + value.translation.width)
                    }
                    .onEnded { _ in startWidth = nil }
            )
            .onTapGesture(count: 2) {
                layout.listWidth = WindowLayout.defaultListWidth
            }
            .hint("Drag to change the width of the list. Double-click for the default width.")
            .accessibilityHidden(true)
    }
}
