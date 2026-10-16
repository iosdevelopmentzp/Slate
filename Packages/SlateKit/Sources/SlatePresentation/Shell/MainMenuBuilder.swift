import AppKit
import SlateEditor

@MainActor
struct MainMenuBuilder {
    struct Command {
        let title: String
        let key: String
        let modifiers: NSEvent.ModifierFlags
        let run: () -> Void
    }

    let app: [Command]
    let file: [Command]
    let note: [Command]
    let go: [Command]
    let view: [Command]
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
            standard("Select All", #selector(NSText.selectAll(_:)), key: "a"),
            .separator(),
            standard("Find in Note", EditorMenuActions.find, key: "f"),
            standard("Find and Replace", EditorMenuActions.findAndReplace, key: "f", modifiers: [.command, .option]),
        ]))
        main.addItem(submenu("Format", items: [
            standard("Bold", EditorMenuActions.bold, key: "b"),
            standard("Italic", EditorMenuActions.italic, key: "i"),
            standard("Insert Link", EditorMenuActions.link, key: "k", modifiers: [.command, .shift]),
            standard("Open Link", EditorMenuActions.openLink, key: "\r"),
            .separator(),
            standard("Toggle Checkbox", EditorMenuActions.toggleCheckbox, key: "l", modifiers: [.command, .shift]),
            standard("Move Line Up", EditorMenuActions.moveLineUp, key: String(UnicodeScalar(NSUpArrowFunctionKey)!), modifiers: [.option]),
            standard("Move Line Down", EditorMenuActions.moveLineDown, key: String(UnicodeScalar(NSDownArrowFunctionKey)!), modifiers: [.option]),
            standard("Duplicate Line", EditorMenuActions.duplicateLine, key: "d"),
            .separator(),
            standard("Screenshot of a Region", EditorMenuActions.screenshot, key: "s", modifiers: [.command, .shift]),
            standard("Screenshot of a Window", EditorMenuActions.windowScreenshot, key: "w", modifiers: [.command, .shift]),
        ]))
        main.addItem(submenu("Note", items: note.map(item)))
        main.addItem(submenu("Go", items: go.map(item)))
        main.addItem(submenu("View", items: view.map(item)))
        let window = submenu("Window", items: [
            standard("Minimize", #selector(NSWindow.performMiniaturize(_:)), key: "m"),
            standard("Zoom", #selector(NSWindow.performZoom(_:))),
        ])
        main.addItem(window)
        NSApp.windowsMenu = window.submenu
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
        item.representedObject = MenuTarget.Action(run: command.run)
        return item
    }
}
