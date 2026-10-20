import AppKit
import SlateEditor

@MainActor
struct MainMenuBuilder {
    struct Command {
        let title: String
        let key: String
        let modifiers: NSEvent.ModifierFlags
        var isOn: (() -> Bool)?
        let run: () -> Void

        init(title: String, key: String, modifiers: NSEvent.ModifierFlags, isOn: (() -> Bool)? = nil, run: @escaping () -> Void) {
            self.title = title
            self.key = key
            self.modifiers = modifiers
            self.isOn = isOn
            self.run = run
        }
    }

    let app: [Command]
    let file: [Command]
    let note: [Command]
    let go: [Command]
    let view: [Command]
    let appearance: [Command]
    let target: MenuTarget

    func build() -> NSMenu {
        let main = NSMenu()
        main.addItem(submenu("Slate", items: [
            standard("About Slate", #selector(NSApplication.orderFrontStandardAboutPanel(_:))),
            .separator(),
        ] + app.map(item) + [
            .separator(),
            standard("Hide Slate", #selector(NSApplication.hide(_:)), key: "h"),
            standard("Quit Slate", #selector(NSApplication.terminate(_:)), key: "q"),
        ]))
        main.addItem(submenu("File", items: file.map(item) + [.separator(), standard("Close Window", #selector(NSWindow.performClose(_:)), key: "w")]))
        main.addItem(submenu("Edit", items: [
            standard("Undo", Selector(("undo:")), key: "z"),
            standard("Redo", Selector(("redo:")), key: "z", modifiers: [.command, .shift]),
            .separator(),
            standard("Cut", #selector(NSText.cut(_:)), key: "x"),
            standard("Copy", #selector(NSText.copy(_:)), key: "c"),
            standard("Paste", #selector(NSText.paste(_:)), key: "v"),
            standard("Paste as Table", EditorMenuActions.pasteTable),
            standard("Select All", #selector(NSText.selectAll(_:)), key: "a"),
            standard("Add Caret Above", EditorMenuActions.caretAbove, key: String(UnicodeScalar(UInt16(NSUpArrowFunctionKey))!), modifiers: [.control, .shift]),
            standard("Add Caret Below", EditorMenuActions.caretBelow, key: String(UnicodeScalar(UInt16(NSDownArrowFunctionKey))!), modifiers: [.control, .shift]),
            .separator(),
            standard("Find in Note", EditorMenuActions.find, key: "f", modifiers: [.command, .option]),
            standard("Go to Heading…", EditorMenuActions.outline, key: "o", modifiers: [.command, .shift]),
            standard("Collapse Section", EditorMenuActions.collapseSection, key: String(UnicodeScalar(UInt16(NSLeftArrowFunctionKey))!), modifiers: [.command, .option]),
            standard("Expand Section", EditorMenuActions.expandSection, key: String(UnicodeScalar(UInt16(NSRightArrowFunctionKey))!), modifiers: [.command, .option]),
            standard("Collapse All Sections", EditorMenuActions.collapseAllSections, key: String(UnicodeScalar(UInt16(NSLeftArrowFunctionKey))!), modifiers: [.command, .option, .shift]),
            standard("Expand All Sections", EditorMenuActions.expandAllSections, key: String(UnicodeScalar(UInt16(NSRightArrowFunctionKey))!), modifiers: [.command, .option, .shift]),
        ]))
        main.addItem(submenu("Format", items: [
            standard("Title", EditorMenuActions.title, key: "t", modifiers: [.command, .shift]),
            standard("Heading", EditorMenuActions.heading, key: "h", modifiers: [.command, .shift]),
            standard("Subheading", EditorMenuActions.subheading, key: "j", modifiers: [.command, .shift]),
            standard("Body", EditorMenuActions.body, key: "b", modifiers: [.command, .shift]),
            standard("Code Block", EditorMenuActions.monospaced, key: "m", modifiers: [.command, .shift]),
            .separator(),
            standard("Checklist", EditorMenuActions.checklist, key: "l", modifiers: [.command, .shift]),
            standard("Bulleted List", EditorMenuActions.bulleted, key: "7", modifiers: [.command, .shift]),
            standard("Numbered List", EditorMenuActions.numbered, key: "9", modifiers: [.command, .shift]),
            standard("Quote", EditorMenuActions.quote, key: "'"),
            standard("Indent", EditorMenuActions.indent, key: "]"),
            standard("Outdent", EditorMenuActions.outdent, key: "["),
            .separator(),
            standard("Bold", EditorMenuActions.bold, key: "b"),
            standard("Italic", EditorMenuActions.italic, key: "i"),
            standard("Strikethrough", EditorMenuActions.strikethrough, key: "x", modifiers: [.command, .shift]),
            ColorMenu.highlightItem(),
            ColorMenu.textColorItem(),
            .separator(),
            standard("Link", EditorMenuActions.link, key: "k"),
            standard("Image", EditorMenuActions.image, key: "i", modifiers: [.command, .shift]),
            standard("Attach File", EditorMenuActions.file, key: "a", modifiers: [.command, .shift]),
            standard("Divider", EditorMenuActions.divider),
            standard("Table", EditorMenuActions.table, key: "t", modifiers: [.command, .option]),
            standard("Format JSON", EditorMenuActions.formatJSON, key: "j", modifiers: [.command, .option, .shift]),
            standard("Screenshot", EditorMenuActions.screenshot, key: "s", modifiers: [.command, .shift]),
        ]))
        main.addItem(submenu("Note", items: note.map(item)))
        main.addItem(submenu("Go", items: go.map(item)))
        main.addItem(submenu("View", items: view.map(item) + [.separator(), submenu("Appearance", items: appearance.map(item))]))
        let window = submenu("Window", items: [
            standard("Minimize", #selector(NSWindow.performMiniaturize(_:)), key: "m"),
            standard("Zoom", #selector(NSWindow.performZoom(_:))),
        ])
        main.addItem(window)
        NSApplication.shared.windowsMenu = window.submenu
        return main
    }

    private func submenu(_ title: String, items: [NSMenuItem]) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        let menu = NSMenu(title: title)
        items.forEach(menu.addItem)
        item.submenu = menu
        return item
    }

    private func standard(_ title: String, _ action: Selector, key: String = "", modifiers: NSEvent.ModifierFlags = [.command]) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.keyEquivalentModifierMask = modifiers
        return item
    }

    private func item(_ command: Command) -> NSMenuItem {
        let item = NSMenuItem(title: command.title, action: #selector(MenuTarget.perform(_:)), keyEquivalent: command.key)
        item.keyEquivalentModifierMask = command.modifiers
        item.target = target
        item.representedObject = MenuTarget.Action(run: command.run, isOn: command.isOn)
        return item
    }
}
