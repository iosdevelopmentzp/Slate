import AppKit

final class CodeCopyButton: NSButton {
    static let side: CGFloat = 22
    static let gap: CGFloat = 4
    static let copiedTime: Duration = .milliseconds(1200)

    private(set) var location: Int?
    var onCopy: (Int) -> Void = { _ in }
    private var resetTask: Task<Void, Never>?

    init() {
        super.init(frame: NSRect(x: 0, y: 0, width: Self.side, height: Self.side))
        imagePosition = .imageOnly
        isBordered = false
        contentTintColor = .secondaryLabelColor
        toolTip = "Copy Code"
        setAccessibilityLabel("Copy Code")
        wantsLayer = true
        layer?.cornerRadius = 5
        target = self
        action = #selector(copyCode)
        isHidden = true
        showIcon(copied: false)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .arrow)
    }

    override func updateLayer() {
        layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.9).cgColor
    }

    func show(location: Int, at origin: CGPoint, in view: NSView) {
        if self.location != location { showIcon(copied: false) }
        self.location = location
        if superview !== view {
            view.addSubview(self)
        }
        frame = NSRect(origin: origin, size: CGSize(width: Self.side, height: Self.side))
        isHidden = false
    }

    func hide() {
        location = nil
        isHidden = true
    }

    private func showIcon(copied: Bool) {
        image = NSImage(systemSymbolName: copied ? "checkmark" : "doc.on.doc", accessibilityDescription: nil)?
            .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 11, weight: .medium))
    }

    @objc private func copyCode() {
        guard let location else { return }
        onCopy(location)
        showIcon(copied: true)
        resetTask?.cancel()
        resetTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: Self.copiedTime)
            guard let self, Task.isCancelled == false else { return }
            showIcon(copied: false)
        }
    }
}
