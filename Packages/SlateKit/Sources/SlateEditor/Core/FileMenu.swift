import AppKit

enum FileMenu {
    static let entries: [(String, AttachmentAction)] = [
        ("Open", .open),
        ("Quick Look", .quickLook),
        ("Show in Finder", .reveal),
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
}
