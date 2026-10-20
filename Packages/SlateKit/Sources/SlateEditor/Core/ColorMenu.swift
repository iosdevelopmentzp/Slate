import AppKit

package enum ColorMenu {
    package static let noneTag = 0

    package static func highlightItem() -> NSMenuItem {
        let items = HighlightColor.allCases.map { color in
            item(color.title, swatch: color.swatch, tag: color.rawValue, action: EditorMenuActions.highlight, key: color == .yellow ? "e" : "")
        }
        return submenu("Highlight", items: items + [.separator(), item("Remove Highlight", swatch: nil, tag: noneTag, action: EditorMenuActions.highlight, key: "")])
    }

    package static func textColorItem() -> NSMenuItem {
        let items = TextColor.allCases.map { color in
            item(color.title, swatch: color.swatch, tag: color.rawValue, action: EditorMenuActions.textColor, key: "")
        }
        return submenu("Text Colour", items: items + [.separator(), item("Default Colour", swatch: nil, tag: noneTag, action: EditorMenuActions.textColor, key: "")])
    }

    static func highlight(from sender: Any?) -> HighlightColor? {
        HighlightColor(rawValue: (sender as? NSValidatedUserInterfaceItem)?.tag ?? noneTag)
    }

    static func textColor(from sender: Any?) -> TextColor? {
        TextColor(rawValue: (sender as? NSValidatedUserInterfaceItem)?.tag ?? noneTag)
    }

    static func prepend(to menu: NSMenu) {
        menu.insertItem(.separator(), at: 0)
        menu.insertItem(textColorItem(), at: 0)
        menu.insertItem(highlightItem(), at: 0)
    }

    static func validate(_ item: NSValidatedUserInterfaceItem, state: EditorStyleState) -> Bool {
        guard let menuItem = item as? NSMenuItem else { return state.canFormatInline }
        if item.action == EditorMenuActions.highlight {
            menuItem.state = item.tag != noneTag && state.highlight?.rawValue == item.tag ? .on : .off
        } else if item.action == EditorMenuActions.textColor {
            menuItem.state = item.tag != noneTag && state.textColor?.rawValue == item.tag ? .on : .off
        }
        return state.canFormatInline
    }

    private static func submenu(_ title: String, items: [NSMenuItem]) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        let menu = NSMenu(title: title)
        items.forEach(menu.addItem)
        item.submenu = menu
        return item
    }

    private static func item(_ title: String, swatch: NSColor?, tag: Int, action: Selector, key: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.keyEquivalentModifierMask = [.command, .shift]
        item.tag = tag
        item.image = swatch.map(image)
        return item
    }

    package static func image(_ color: NSColor) -> NSImage {
        let image = NSImage(size: NSSize(width: 12, height: 12), flipped: false) { rect in
            color.setFill()
            NSBezierPath(ovalIn: rect.insetBy(dx: 0.5, dy: 0.5)).fill()
            NSColor.black.withAlphaComponent(0.15).setStroke()
            NSBezierPath(ovalIn: rect.insetBy(dx: 0.5, dy: 0.5)).stroke()
            return true
        }
        image.isTemplate = false
        return image
    }
}
