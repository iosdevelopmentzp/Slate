import AppKit

enum ImageMenu {
    static let entries: [(String, AttachmentAction)] = [
        ("Quick Look", .quickLook),
        ("Open", .open),
        ("Show in Finder", .reveal),
        ("Copy Image", .copyImage),
        ("Save to Downloads", .saveToDownloads),
    ]

    static func items(path: String, target: AnyObject, action: Selector) -> [NSMenuItem] {
        entries.map { title, choice in
            let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
            item.representedObject = ImageMenuChoice(path: path, action: choice)
            item.target = target
            return item
        }
    }

    static func prepend(path: String, target: AnyObject, action: Selector, to menu: NSMenu) -> NSMenu {
        let items = items(path: path, target: target, action: action)
        if menu.items.isEmpty == false {
            menu.insertItem(.separator(), at: 0)
        }
        for item in items.reversed() {
            menu.insertItem(item, at: 0)
        }
        return menu
    }
}
