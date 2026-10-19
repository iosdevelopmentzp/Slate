import AppKit

enum LinkMenu {
    static func prepend(range: NSRange, target: AnyObject, action: Selector, to menu: NSMenu) {
        for (position, choice) in LinkAction.allCases.enumerated() {
            let item = NSMenuItem(title: choice.title, action: action, keyEquivalent: "")
            item.target = target
            item.tag = choice.rawValue
            item.representedObject = NSValue(range: range)
            menu.insertItem(item, at: position)
        }
        menu.insertItem(.separator(), at: LinkAction.allCases.count)
    }
}
