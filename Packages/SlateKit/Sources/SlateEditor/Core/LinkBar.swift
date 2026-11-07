import AppKit

final class LinkBar: NSView {
    static let height: CGFloat = 40
    static let gap: CGFloat = 4

    var onAction: (LinkAction, NSRange) -> Void = { _, _ in }
    private(set) var range: NSRange?
    let preview = LinkPreviewView()
    private let stack = NSStackView()
    private var buttons: [LinkAction: NSView] = [:]

    init() {
        super.init(frame: .zero)
        isHidden = true
        preview.onOpen = { [weak self] in
            guard let self, let range else { return }
            onAction(.open, range)
        }
        preview.heightAnchor.constraint(equalToConstant: Self.height - 8).isActive = true
        let actions = LinkAction.allCases.filter { $0 != .open }
        for action in actions { buttons[action] = button(for: action) }
        stack.setViews([preview] + actions.compactMap { buttons[$0] }, in: .leading)
        stack.orientation = .horizontal
        stack.spacing = 2
        stack.edgeInsets = NSEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
        stack.setCustomSpacing(6, after: preview)
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
        show(LinkPreview(href: href), address: LinkAddress.display(href), editable: true, range: range, below: rect, in: view)
    }

    func show(reference: TextReference, text: String, range: NSRange, below rect: CGRect, in view: NSView) {
        show(LinkPreview(reference: reference), address: text, editable: false, range: range, below: rect, in: view)
    }

    private func show(_ model: LinkPreview, address: String, editable: Bool, range: NSRange, below rect: CGRect, in view: NSView) {
        self.range = range
        buttons[.edit]?.isHidden = editable == false
        buttons[.remove]?.isHidden = editable == false
        preview.show(model, address: address)
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
