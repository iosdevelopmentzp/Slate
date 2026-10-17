import AppKit
import KeyboardShortcuts
import SwiftUI
import SlateDomain
import SlateUI

@MainActor
package final class AppWindows: NSObject, NSWindowDelegate {
    private let assembly: PresentationAssembly
    private let statusItem: NSStatusItem
    private let panel: MenuBarPanel
    private var window: NSWindow?
    private var clickMonitor: Any?
    private var resignObserver: NSObjectProtocol?
    private var lastPanelTopLeft: CGPoint?
    private var isCapturing = false
    private let capturePanel = CapturePanel()
    private var captureMonitor: Any?
    private var settingsWindow: NSWindow?
    package var onChangeVault: (URL) -> Void = { _ in }
    private let menuTarget = MenuTarget()

    private var layout: WindowLayout {
        assembly.layout
    }

    package init(assembly: PresentationAssembly) {
        self.assembly = assembly
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        panel = MenuBarPanel()
        super.init()
    }

    package func start() {
        lastPanelTopLeft = layout.panelTopLeft
        assembly.panelVisibility.hideForCapture = { [weak self] in
            guard let self else { return }
            hidePanelForCapture()
        }
        assembly.panelVisibility.showAfterCapture = { [weak self] in
            guard let self else { return }
            showPanelAfterCapture()
        }
        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "note.text", accessibilityDescription: "Slate")
            image?.isTemplate = true
            button.image = image
            button.target = self
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseDown, .rightMouseDown])
        }
        observeLayout()
        observeAppearance()
        registerHotkeys()
        assembly.settings.extraChecks = {
            let names: [(KeyboardShortcuts.Name, String)] = [(.togglePanel, "Open Slate"), (.capture, "Quick note"), (.newNote, "New note")]
            return names.map { name, title in
                let shortcut = KeyboardShortcuts.getShortcut(for: name)
                return DoctorCheck(id: "hotkey.\(name.rawValue)", title: title, isOK: shortcut != nil, detail: shortcut.map { "\($0)" } ?? "No shortcut set")
            }
        }
        assembly.settings.changeVault = { [weak self] in
            guard let self else { return }
            chooseVault()
        }
        capturePanel.onCancel = { [weak self] in
            guard let self else { return }
            closeCapture()
        }
        panel.onCancel = { [weak self] in
            guard let self else { return }
            if assembly.search.isActive {
                assembly.search.clear()
            } else {
                closePanel()
            }
        }
        resignObserver = NotificationCenter.default.addObserver(forName: NSApplication.didResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                closePanel()
            }
        }
    }

    package func showWindowOrPanel() {
        if let window, window.isVisible {
            NSApp.activate()
            window.makeKeyAndOrderFront(nil)
            return
        }
        togglePanel()
    }

    func togglePanel() {
        if panel.isVisible {
            closePanel()
        } else {
            showPanel()
        }
    }

    func openWindow() {
        closePanel()
        if window != nil {
            layout.openCount += 1
        }
        let window = window ?? makeWindow()
        self.window = window
        if window.setFrameUsingName(WindowLayout.windowAutosaveName) == false {
            window.setContentSize(layout.size)
            window.center()
        }
        window.setFrameAutosaveName(WindowLayout.windowAutosaveName)
        NSApp.setActivationPolicy(.regular)
        NSApp.mainMenu = mainMenu()
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    package func windowWillClose(_ notification: Notification) {
        Task { await assembly.flush() }
        guard (notification.object as? NSWindow) === window else { return }
        NSApp.setActivationPolicy(.accessory)
    }

    private func mainMenu() -> NSMenu {
        let noteList = assembly.noteList
        let search = assembly.search
        let layout = layout
        let spaces = assembly.vault.spaces
        let vault = assembly.vault
        let settings = assembly.settings
        let selectNeighbour: (Int) -> Void = { offset in
            noteList.selectNeighbour(offset, in: search.isActive ? search.results.map(\.summary) : nil)
        }
        typealias Command = MainMenuBuilder.Command
        var go: [Command] = [
            Command(title: "Previous Note", key: String(UnicodeScalar(NSUpArrowFunctionKey)!), modifiers: [.command]) {
                if TextFocus.isEditingText { TextFocus.send(#selector(NSResponder.moveToBeginningOfDocument(_:))) } else { selectNeighbour(-1) }
            },
            Command(title: "Next Note", key: String(UnicodeScalar(NSDownArrowFunctionKey)!), modifiers: [.command]) {
                if TextFocus.isEditingText { TextFocus.send(#selector(NSResponder.moveToEndOfDocument(_:))) } else { selectNeighbour(1) }
            },
            Command(title: "Previous Folder", key: "[", modifiers: [.command, .shift]) { noteList.show(ListSource.cycle(from: noteList.source, spaces: spaces.map(\.folder), by: -1)) },
            Command(title: "Next Folder", key: "]", modifiers: [.command, .shift]) { noteList.show(ListSource.cycle(from: noteList.source, spaces: spaces.map(\.folder), by: 1)) },
            Command(title: "All Notes", key: "", modifiers: []) { noteList.show(.all) },
        ]
        for (position, space) in spaces.prefix(9).enumerated() {
            go.append(Command(title: space.folder.rawValue, key: "\(position + 1)", modifiers: [.command]) { noteList.show(.space(space.folder)) })
        }
        let builder = MainMenuBuilder(
            app: [Command(title: "Settings…", key: ",", modifiers: [.command]) { [weak self] in self?.openSettings() }],
            file: [
                Command(title: "New Note", key: "n", modifiers: [.command]) { Task { await noteList.createNote() } },
                Command(title: "New Folder", key: "n", modifiers: [.command, .shift]) {
                    layout.showsSidebar = true
                    vault.startNewFolder()
                },
                Command(title: "Quick Note", key: "", modifiers: []) { [weak self] in self?.showCapture() },
            ],
            note: [
                Command(title: "Pin or Unpin", key: "p", modifiers: [.command, .shift]) {
                    guard let selected = noteList.selected else { return }
                    Task { await noteList.togglePin(selected) }
                },
                Command(title: "Move to Trash", key: String(UnicodeScalar(NSBackspaceCharacter)!), modifiers: [.command]) {
                    if TextFocus.isEditingText {
                        TextFocus.send(#selector(NSResponder.deleteToBeginningOfLine(_:)))
                    } else if let selected = noteList.selected {
                        noteList.requestTrash(selected.id)
                    }
                },
            ],
            go: go,
            view: [Command(title: "Show or Hide the Sidebar", key: "0", modifiers: [.command]) { layout.showsSidebar.toggle() }],
            appearance: AppAppearance.allCases.map { choice in
                Command(title: choice.title, key: "", modifiers: [], isOn: { settings.appearance == choice }) { settings.appearance = choice }
            },
            target: menuTarget
        )
        return builder.build()
    }

    package func windowDidResignKey(_ notification: Notification) {
        Task { await assembly.flush() }
    }

    private func hidePanelForCapture() {
        guard panel.isVisible else { return }
        isCapturing = true
        removeClickMonitor()
        panel.orderOut(nil)
    }

    private func showPanelAfterCapture() {
        guard isCapturing else { return }
        isCapturing = false
        NSApp.activate()
        panel.makeKeyAndOrderFront(nil)
        installClickMonitor()
    }

    private func removeClickMonitor() {
        guard let clickMonitor else { return }
        NSEvent.removeMonitor(clickMonitor)
        self.clickMonitor = nil
    }

    package func stop() {
        KeyboardShortcuts.removeAllHandlers()
        closePanel()
        closeCapture()
        window?.close()
        settingsWindow?.close()
        if let resignObserver {
            NotificationCenter.default.removeObserver(resignObserver)
        }
        NSStatusBar.system.removeStatusItem(statusItem)
    }

    private func chooseVault() {
        let current = URL(fileURLWithPath: assembly.settings.vaultPath, isDirectory: true)
        guard let folder = FolderPicker.chooseFolder(directory: current.deletingLastPathComponent(), prompt: "Use This Folder", message: "Choose the folder for your notes.") else { return }
        onChangeVault(folder)
    }

    package func handle(_ command: URLCommand) {
        switch command {
        case .capture:
            showCapture()
        case .search(let text):
            showPanelIfHidden()
            assembly.search.query = text
        case .new(let draft):
            showPanelIfHidden()
            Task { await assembly.noteList.create(draft) }
        case .open(let target):
            showPanelIfHidden()
            Task { await assembly.noteList.open(target) }
        case .append(let text, let target, let section):
            Task { await assembly.noteList.append(text, to: target, section: section) }
        }
    }

    package func addFromService(_ text: String) {
        Task { await assembly.capture.addFromService(text) }
    }

    private func showPanelIfHidden() {
        if window?.isVisible == true {
            NSApp.activate()
            window?.makeKeyAndOrderFront(nil)
        } else if panel.isVisible == false {
            showPanel()
        }
    }

    func openSettings() {
        closePanel()
        let window = settingsWindow ?? makeSettingsWindow()
        settingsWindow = window
        applyAppearance()
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    func toggleCapture() {
        if capturePanel.isVisible {
            closeCapture()
        } else {
            showCapture()
        }
    }

    func newNoteFromHotkey() {
        if window?.isVisible != true, panel.isVisible == false {
            showPanel()
        }
        Task { await assembly.noteList.createNote() }
    }

    private func registerHotkeys() {
        KeyboardShortcuts.onKeyUp(for: .togglePanel) { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                showWindowOrPanel()
            }
        }
        KeyboardShortcuts.onKeyUp(for: .capture) { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                toggleCapture()
            }
        }
        KeyboardShortcuts.onKeyUp(for: .newNote) { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                newNoteFromHotkey()
            }
        }
    }

    private func showCapture() {
        if capturePanel.contentViewController == nil {
            let root = CaptureView(
                onSave: { [weak self] in
                    guard let self else { return }
                    saveCapture(open: false)
                },
                onOpen: { [weak self] in
                    guard let self else { return }
                    saveCapture(open: true)
                },
                onCancel: { [weak self] in
                    guard let self else { return }
                    closeCapture()
                }
            )
            .inject(assembly)
            let controller = NSHostingController(rootView: root)
            controller.sizingOptions = [.preferredContentSize]
            capturePanel.contentViewController = controller
        }
        applyAppearance()
        capturePanel.setFrameOrigin(captureOrigin())
        capturePanel.alphaValue = 0
        capturePanel.orderFrontRegardless()
        capturePanel.makeKey()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            capturePanel.animator().alphaValue = 1
        }
        assembly.capture.prepare()
        installCaptureMonitor()
    }

    private func saveCapture(open: Bool) {
        Task {
            guard await assembly.capture.save(select: open) != nil else { return }
            closeCapture()
            if open {
                showPanel()
            }
        }
    }

    private func closeCapture() {
        guard capturePanel.isVisible else { return }
        capturePanel.orderOut(nil)
        if let captureMonitor {
            NSEvent.removeMonitor(captureMonitor)
            self.captureMonitor = nil
        }
    }

    private func installCaptureMonitor() {
        guard captureMonitor == nil else { return }
        captureMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                closeCapture()
            }
        }
    }

    private func captureOrigin() -> CGPoint {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
        let visible = screen?.visibleFrame ?? .zero
        let size = capturePanel.frame.size
        return CGPoint(x: visible.midX - size.width / 2, y: visible.maxY - visible.height * 0.2 - size.height)
    }

    private func makeSettingsWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 480),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Slate Settings"
        window.isReleasedWhenClosed = false
        window.contentViewController = NSHostingController(rootView: SettingsView().inject(assembly))
        window.center()
        window.setFrameAutosaveName("SlateSettings")
        return window
    }

    private func observeAppearance() {
        withObservationTracking {
            _ = assembly.settings.appearance
        } onChange: {
            Task { @MainActor [weak self] in
                guard let self else { return }
                applyAppearance()
                observeAppearance()
            }
        }
    }

    private var currentAppearance: NSAppearance? {
        switch assembly.settings.appearance {
        case .system: nil
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        }
    }

    private func applyAppearance() {
        let appearance = currentAppearance
        for target in [panel, capturePanel, window, settingsWindow].compactMap({ $0 }) {
            target.appearance = appearance
        }
    }

    private func statusMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(item("New Note", key: "n", action: #selector(menuNewNote)))
        menu.addItem(item("Quick Note", action: #selector(menuCapture)))
        menu.addItem(.separator())
        menu.addItem(item("Open Window", key: "o", modifiers: [.command, .shift], action: #selector(menuOpenWindow)))
        menu.addItem(item("Settings…", key: ",", action: #selector(menuSettings)))
        menu.addItem(appearanceMenuItem())
        menu.addItem(.separator())
        menu.addItem(item("Quit Slate", key: "q", action: #selector(menuQuit)))
        return menu
    }

    private func item(_ title: String, key: String = "", modifiers: NSEvent.ModifierFlags = [.command], action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.keyEquivalentModifierMask = modifiers
        item.target = self
        return item
    }

    @objc private func menuNewNote() {
        showPanel()
        Task { await assembly.noteList.createNote() }
    }

    @objc private func menuCapture() {
        showCapture()
    }

    @objc private func menuOpenWindow() {
        openWindow()
    }

    private func appearanceMenuItem() -> NSMenuItem {
        let parent = NSMenuItem(title: "Appearance", action: nil, keyEquivalent: "")
        let submenu = NSMenu(title: "Appearance")
        for choice in AppAppearance.allCases {
            let entry = item(choice.title, key: "", modifiers: [], action: #selector(menuAppearance(_:)))
            entry.representedObject = choice.rawValue
            entry.state = assembly.settings.appearance == choice ? .on : .off
            submenu.addItem(entry)
        }
        parent.submenu = submenu
        return parent
    }

    @objc private func menuAppearance(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let choice = AppAppearance(rawValue: raw) else { return }
        assembly.settings.appearance = choice
    }

    @objc private func menuSettings() {
        openSettings()
    }

    @objc private func menuQuit() {
        NSApp.terminate(nil)
    }

    @objc private func statusItemClicked() {
        if NSApp.currentEvent?.type == .rightMouseDown {
            closePanel()
            statusItem.menu = statusMenu()
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
            return
        }
        togglePanel()
    }

    private func showPanel() {
        if panel.contentViewController == nil {
            panel.contentViewController = hostingController(surface: .panel)
        } else {
            layout.openCount += 1
        }
        panel.setFrame(layout.panelFrame(anchor: iconAnchor(), anchorScreen: statusItem.button?.window?.screen), display: false)
        applyAppearance()
        NSApp.activate()
        panel.makeKeyAndOrderFront(nil)
        panel.invalidateShadow()
        statusItem.button?.highlight(true)
        installClickMonitor()
    }

    private func closePanel() {
        guard panel.isVisible, isCapturing == false else { return }
        Task { await assembly.flush() }
        panel.orderOut(nil)
        statusItem.button?.highlight(false)
        removeClickMonitor()
    }

    private func installClickMonitor() {
        guard clickMonitor == nil else { return }
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                closePanel()
            }
        }
    }

    private func iconAnchor() -> CGPoint {
        guard let button = statusItem.button, let window = button.window else {
            let visible = NSScreen.main?.visibleFrame ?? .zero
            return CGPoint(x: visible.maxX - layout.size.width, y: visible.maxY)
        }
        let frame = window.convertToScreen(button.convert(button.bounds, to: nil))
        return CGPoint(x: frame.midX - layout.size.width / 2, y: frame.minY - 4)
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: layout.size),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Slate"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isReleasedWhenClosed = false
        window.contentMinSize = WindowLayout.minimumSize
        window.delegate = self
        window.contentViewController = hostingController(surface: .window)
        return window
    }

    private func hostingController(surface: Surface) -> NSViewController {
        let root = RootView()
            .inject(assembly)
            .environment(\.surface, surface)
            .environment(\.openAsWindow, { [weak self] in
                guard let self else { return }
                openWindow()
            })
            .environment(\.openSettings, { [weak self] in
                guard let self else { return }
                openSettings()
            })
        let controller = NSHostingController(rootView: root)
        controller.sizingOptions = surface == .window ? [.minSize] : []
        return controller
    }

    private func observeLayout() {
        withObservationTracking {
            _ = layout.size
            _ = layout.panelTopLeft
        } onChange: {
            Task { @MainActor [weak self] in
                guard let self else { return }
                applyLayout()
                observeLayout()
            }
        }
    }

    private func applyLayout() {
        let returnsToIcon = lastPanelTopLeft != nil && layout.panelTopLeft == nil
        lastPanelTopLeft = layout.panelTopLeft
        guard panel.isVisible else { return }
        if returnsToIcon {
            panel.setFrame(layout.panelFrame(anchor: iconAnchor(), anchorScreen: statusItem.button?.window?.screen), display: true)
            return
        }
        layout.fit(panel)
    }
}
