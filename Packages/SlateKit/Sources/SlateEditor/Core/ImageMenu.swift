import AppKit

enum ImageMenu {
    static let entries: [(String, AttachmentAction)] = [
        ("Quick Look", .quickLook),
        ("Open", .open),
        ("Show in Finder", .reveal),
        ("Copy Image", .copyImage),
        ("Save to Downloads", .saveToDownloads),
    ]

    static let textSizes: [(String, Int?)] = [("Small", 240), ("Medium", 420), ("Large", 640), ("Original Size", nil)]
    static let cellSizes: [(String, Int?)] = [("Small", 60), ("Medium", 120), ("Large", 200), ("Default Size", nil)]

    static func sizeItem(_ sizes: [(String, Int?)], current: CGFloat?, target: AnyObject, action: Selector, choice: (Int?) -> ImageSizeChoice) -> NSMenuItem {
        let submenu = NSMenu()
        for (title, width) in sizes {
            let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
            item.target = target
            item.representedObject = choice(width)
            item.state = current.map(Int.init) == width ? .on : .off
            submenu.addItem(item)
        }
        let item = NSMenuItem(title: "Size", action: nil, keyEquivalent: "")
        item.submenu = submenu
        return item
    }

    static func items(path: String, target: AnyObject, action: Selector) -> [NSMenuItem] {
        entries.map { title, choice in
            let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
            item.representedObject = ImageMenuChoice(path: path, action: choice)
            item.target = target
            return item
        }
    }

    static func prepend(path: String, target: AnyObject, action: Selector, size: NSMenuItem? = nil, to menu: NSMenu) -> NSMenu {
        let items = items(path: path, target: target, action: action) + (size.map { [$0] } ?? [])
        if menu.items.isEmpty == false {
            menu.insertItem(.separator(), at: 0)
        }
        for item in items.reversed() {
            menu.insertItem(item, at: 0)
        }
        return menu
    }
}
