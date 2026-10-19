import AppKit
import SlateUI

final class MainWindow: NSWindow {
    var onCancel: () -> Void = {}

    override func cancelOperation(_ sender: Any?) {
        onCancel()
    }

    init(size: CGSize) {
        super.init(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        title = "Slate"
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        isReleasedWhenClosed = false
        contentMinSize = WindowLayout.minimumSize
        collectionBehavior.insert(.moveToActiveSpace)
    }
}
