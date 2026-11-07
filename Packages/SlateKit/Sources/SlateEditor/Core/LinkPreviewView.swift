import AppKit

final class LinkPreviewView: NSView {
    static let tileSide: CGFloat = 28
    static let textWidth: CGFloat = 260

    var onOpen: () -> Void = {}
    private let tile = NSView()
    private let icon = NSImageView()
    private let title = NSTextField(labelWithString: "")
    private let detail = NSTextField(labelWithString: "")
    private var isHovered = false {
        didSet { needsDisplay = true }
    }
    private var isPressed = false {
        didSet { needsDisplay = true }
    }

    init() {
        super.init(frame: .zero)
        tile.wantsLayer = true
        tile.layer?.cornerRadius = 6
        icon.contentTintColor = .controlAccentColor
        icon.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
        title.font = .systemFont(ofSize: 12, weight: .semibold)
        detail.font = .systemFont(ofSize: 11)
        detail.textColor = .secondaryLabelColor
        for label in [title, detail] {
            label.lineBreakMode = .byTruncatingMiddle
            label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            label.widthAnchor.constraint(lessThanOrEqualToConstant: Self.textWidth).isActive = true
        }
        let lines = NSStackView(views: [title, detail])
        lines.orientation = .vertical
        lines.alignment = .leading
        lines.spacing = 1
        icon.translatesAutoresizingMaskIntoConstraints = false
        tile.addSubview(icon)
        let row = NSStackView(views: [tile, lines])
        row.orientation = .horizontal
        row.spacing = 8
        row.edgeInsets = NSEdgeInsets(top: 0, left: 6, bottom: 0, right: 8)
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)
        NSLayoutConstraint.activate([
            tile.widthAnchor.constraint(equalToConstant: Self.tileSide),
            tile.heightAnchor.constraint(equalToConstant: Self.tileSide),
            icon.centerXAnchor.constraint(equalTo: tile.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: tile.centerYAnchor),
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor),
            row.topAnchor.constraint(equalTo: topAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        wantsLayer = true
        setAccessibilityElement(true)
        setAccessibilityRole(.button)
    }

    required init?(coder: NSCoder) {
        nil
    }

    var titleText: String {
        title.stringValue
    }

    func show(_ preview: LinkPreview, address: String) {
        icon.image = NSImage(systemSymbolName: preview.symbol, accessibilityDescription: nil)
        title.stringValue = preview.title
        detail.stringValue = preview.detail
        toolTip = address
        setAccessibilityLabel("Open \(preview.title)")
        isHovered = false
        isPressed = false
    }

    override var wantsUpdateLayer: Bool {
        true
    }

    override func updateLayer() {
        layer?.cornerRadius = 6
        let tint = NSColor.labelColor.withAlphaComponent(isPressed ? 0.12 : isHovered ? 0.06 : 0)
        layer?.backgroundColor = tint.cgColor
        tile.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.14).cgColor
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect], owner: self, userInfo: nil))
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .pointingHand)
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
    }

    override func mouseDown(with event: NSEvent) {
        isPressed = true
    }

    override func mouseUp(with event: NSEvent) {
        let inside = bounds.contains(convert(event.locationInWindow, from: nil))
        isPressed = false
        guard inside else { return }
        onOpen()
    }

    override func accessibilityPerformPress() -> Bool {
        onOpen()
        return true
    }
}
