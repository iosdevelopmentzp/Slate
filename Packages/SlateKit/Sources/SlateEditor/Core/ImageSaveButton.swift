import AppKit

final class ImageSaveButton: NSButton {
    static let side: CGFloat = 28
    static let inset: CGFloat = 8
    static let smallestImage: CGFloat = 56

    private(set) var path: String?
    var onSave: (String) -> Void = { _ in }

    init() {
        super.init(frame: NSRect(x: 0, y: 0, width: Self.side, height: Self.side))
        image = NSImage(systemSymbolName: "arrow.down.to.line", accessibilityDescription: "Save to Downloads")?.withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 13, weight: .semibold))
        imagePosition = .imageOnly
        isBordered = false
        contentTintColor = .white
        toolTip = "Save to Downloads"
        wantsLayer = true
        layer?.cornerRadius = Self.side / 2
        layer?.backgroundColor = NSColor.black.withAlphaComponent(0.55).cgColor
        target = self
        action = #selector(save)
        isHidden = true
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .arrow)
    }

    func show(path: String, over image: CGRect, in view: NSView) {
        guard image.width >= Self.smallestImage, image.height >= Self.smallestImage else {
            hide()
            return
        }
        self.path = path
        if superview !== view {
            view.addSubview(self)
        }
        let y = view.isFlipped ? image.minY + Self.inset : image.maxY - Self.inset - Self.side
        frame = NSRect(x: image.maxX - Self.inset - Self.side, y: y, width: Self.side, height: Self.side)
        isHidden = false
    }

    func hide() {
        path = nil
        isHidden = true
    }

    @objc private func save() {
        guard let path else { return }
        onSave(path)
    }
}
