import AppKit
import SwiftUI
import SlateUI

struct ColumnResizer: View {
    enum Column {
        case sidebar
        case list
    }

    let column: Column

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
                        let start = startWidth ?? width
                        startWidth = start
                        width = start + value.translation.width
                    }
                    .onEnded { _ in startWidth = nil }
            )
            .onTapGesture(count: 2) {
                width = defaultWidth
            }
            .hint(hint)
            .accessibilityHidden(true)
    }

    private var width: CGFloat {
        get {
            switch column {
            case .sidebar: layout.sidebarWidth
            case .list: layout.listWidth
            }
        }
        nonmutating set {
            switch column {
            case .sidebar: layout.sidebarWidth = WindowLayout.clampedSidebarWidth(newValue)
            case .list: layout.listWidth = WindowLayout.clampedListWidth(newValue)
            }
        }
    }

    private var defaultWidth: CGFloat {
        switch column {
        case .sidebar: WindowLayout.defaultSidebarWidth
        case .list: WindowLayout.defaultListWidth
        }
    }

    private var hint: String {
        switch column {
        case .sidebar: "Drag to change the width of the folders. Double-click for the default width."
        case .list: "Drag to change the width of the list. Double-click for the default width."
        }
    }
}
