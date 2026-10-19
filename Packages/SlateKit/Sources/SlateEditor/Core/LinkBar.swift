import AppKit

final class LinkBar: NSView {
    static let height: CGFloat = 30
    static let gap: CGFloat = 4
    static let addressWidth: CGFloat = 260

    var onAction: (LinkAction, NSRange) -> Void = { _, _ in }
    private(set) var range: NSRange?
    private let icon = NSImageView()
    private let address = NSTextField(labelWithString: "")
    private let stack = NSStackView()

    init() {
        super.init(frame: .zero)
        isHidden = true
        address.lineBreakMode = .byTruncatingMiddle
        address.font = .systemFont(ofSize: 12)
        address.textColor = .secondaryLabelColor
        address.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        address.widthAnchor.constraint(lessThanOrEqualToConstant: Self.addressWidth).isActive = true
        icon.contentTintColor = .secondaryLabelColor
        stack.setViews([icon, address] + LinkAction.allCases.map(button), in: .leading)
        stack.orientation = .horizontal
        stack.spacing = 2
        stack.edgeInsets = NSEdgeInsets(top: 0, left: 10, bottom: 0, right: 4)
        stack.setCustomSpacing(6, after: icon)
        stack.setCustomSpacing(8, after: address)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        setAccessibilityRole(.group)
        setAccessibilityLabel("Link")
    }

    required init?(coder: NSCoder) {
        nil
    }

    override var wantsUpdateLayer: Bool {
        true
    }

    override func updateLayer() {
        guard let layer else { return }
        layer.cornerRadius = 8
        layer.borderWidth = 1
        layer.borderColor = NSColor.separatorColor.cgColor
        layer.backgroundColor = NSColor.controlBackgroundColor.cgColor
        layer.shadowColor = NSColor.black.cgColor
        layer.shadowOpacity = 0.12
        layer.shadowRadius = 4
        layer.shadowOffset = CGSize(width: 0, height: -1)
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .arrow)
    }

    override func mouseDown(with event: NSEvent) {}

    private func button(for action: LinkAction) -> NSView {
        let image = NSImage(systemSymbolName: action.symbol, accessibilityDescription: action.title)?
            .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 12, weight: .medium)) ?? NSImage()
        let button = NSButton(image: image, target: self, action: #selector(runAction(_:)))
        button.isBordered = false
        button.tag = action.rawValue
        button.toolTip = action.title
        button.contentTintColor = .secondaryLabelColor
        button.setAccessibilityLabel(action.title)
        button.widthAnchor.constraint(equalToConstant: 26).isActive = true
        button.heightAnchor.constraint(equalToConstant: 24).isActive = true
        return button
    }

    func show(href: String, range: NSRange, below rect: CGRect, in view: NSView) {
        self.range = range
        icon.image = NSImage(systemSymbolName: LinkAddress.isNote(href) ? "doc.text" : "globe", accessibilityDescription: nil)
        address.stringValue = LinkAddress.display(href)
        address.toolTip = address.stringValue
        if superview === view {
            view.addSubview(self, positioned: .above, relativeTo: nil)
        } else {
            view.addSubview(self)
        }
        let size = CGSize(width: ceil(stack.fittingSize.width), height: Self.height)
        let visible = view.visibleRect
        let x = max(min(rect.minX, visible.maxX - size.width - 4), visible.minX + 4)
        let y = view.isFlipped ? rect.maxY + Self.gap : rect.minY - Self.gap - size.height
        frame = CGRect(origin: CGPoint(x: x, y: y), size: size)
        isHidden = false
        needsDisplay = true
    }

    func hide() {
        range = nil
        isHidden = true
    }

    @objc private func runAction(_ sender: NSButton) {
        guard let range, let action = LinkAction(rawValue: sender.tag) else { return }
        onAction(action, range)
    }
}
