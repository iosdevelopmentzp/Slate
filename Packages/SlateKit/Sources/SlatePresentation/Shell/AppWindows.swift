import AppKit
import SwiftUI
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
        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "note.text", accessibilityDescription: "Slate")
            image?.isTemplate = true
            button.image = image
            button.target = self
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseDown, .rightMouseDown])
        }
        observeLayout()
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
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    package func windowWillClose(_ notification: Notification) {
        Task { await assembly.flush() }
    }

    package func windowDidResignKey(_ notification: Notification) {
        Task { await assembly.flush() }
    }

    @objc private func statusItemClicked() {
        togglePanel()
    }

    private func showPanel() {
        if panel.contentViewController == nil {
            panel.contentViewController = hostingController(surface: .panel)
        } else {
            layout.openCount += 1
        }
        panel.setFrame(layout.panelFrame(anchor: iconAnchor(), anchorScreen: statusItem.button?.window?.screen), display: false)
        NSApp.activate()
        panel.makeKeyAndOrderFront(nil)
        panel.invalidateShadow()
        statusItem.button?.highlight(true)
        installClickMonitor()
    }

    private func closePanel() {
        guard panel.isVisible else { return }
        Task { await assembly.flush() }
        panel.orderOut(nil)
        statusItem.button?.highlight(false)
        if let clickMonitor {
            NSEvent.removeMonitor(clickMonitor)
            self.clickMonitor = nil
        }
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
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Slate"
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
