import AppKit
import SwiftUI

@MainActor
package final class FirstLaunchWindow {
    private var window: NSWindow?

    package init() {}

    package func show(defaultFolder: URL, problem: String?, onStart: @escaping (URL) -> Void) {
        let view = FirstLaunchView(defaultFolder: defaultFolder, problem: problem) { [weak self] folder in
            guard let self else { return }
            close()
            onStart(folder)
        }
        let window = NSWindow(contentViewController: NSHostingController(rootView: view))
        window.title = "Slate"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.center()
        self.window = window
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    package func close() {
        window?.close()
        window = nil
    }
}
