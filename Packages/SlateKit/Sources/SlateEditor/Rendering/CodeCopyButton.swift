import AppKit

final class CodeCopyButton: NSButton {
    var blockRange: NSRange?

    init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 52, height: 20))
        title = "Copy"
        bezelStyle = .accessoryBarAction
        controlSize = .small
        font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        toolTip = "Copy the code"
        setAccessibilityLabel("Copy the code")
        isHidden = true
    }

    required init?(coder: NSCoder) {
        nil
    }
}
