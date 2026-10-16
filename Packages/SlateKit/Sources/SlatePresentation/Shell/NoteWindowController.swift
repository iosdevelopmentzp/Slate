import AppKit
import SwiftUI
import SlateDomain

final class NoteWindowController: NSObject, NSWindowDelegate {
    let window: NSWindow
    let store: EditorStore
    var onClose: (NoteWindowController) -> Void = { _ in }

    init(store: EditorStore, assembly: PresentationAssembly, floating: Bool) {
        self.store = store
        let style: NSWindow.StyleMask = floating ? [.titled, .closable, .resizable, .utilityWindow] : [.titled, .closable, .miniaturizable, .resizable]
        window = floating
            ? NSPanel(contentRect: NSRect(x: 0, y: 0, width: 420, height: 520), styleMask: style, backing: .buffered, defer: false)
            : NSWindow(contentRect: NSRect(x: 0, y: 0, width: 640, height: 600), styleMask: style, backing: .buffered, defer: false)
        super.init()
        window.isReleasedWhenClosed = false
        window.delegate = self
        if floating {
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            window.hidesOnDeactivate = false
            (window as? NSPanel)?.isFloatingPanel = true
            (window as? NSPanel)?.becomesKeyOnlyIfNeeded = false
        }
        let root = NoteWindowView()
            .inject(assembly)
            .environment(store)
            .environment(\.surface, .floating)
        window.contentViewController = NSHostingController(rootView: root)
        window.setContentSize(floating ? NSSize(width: 420, height: 520) : NSSize(width: 640, height: 600))
        window.center()
    }

    func show(_ id: NoteID) {
        Task {
            await store.open(id)
            window.title = store.document?.title ?? "Slate"
        }
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        Task {
            await store.flush()
            onClose(self)
        }
    }

    func windowDidResignKey(_ notification: Notification) {
        Task { await store.flush() }
    }
}
