import AppKit

package enum CalloutMenu {
    package static func item() -> NSMenuItem {
        let item = NSMenuItem(title: "Callout", action: nil, keyEquivalent: "")
        let menu = NSMenu(title: "Callout")
        for kind in CalloutKind.menuKinds {
            let entry = NSMenuItem(title: kind.title, action: #selector(RichTextView.slateCallout(_:)), keyEquivalent: "")
            entry.representedObject = kind.marker
            entry.image = NSImage(systemSymbolName: kind.symbol, accessibilityDescription: nil)
            menu.addItem(entry)
        }
        item.submenu = menu
        return item
    }
}
