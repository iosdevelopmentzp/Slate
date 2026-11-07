import AppKit

final class NoteSuggestionList: NSView {
    static let width: CGFloat = 300
    static let rowHeight: CGFloat = 26
    static let inset: CGFloat = 4

    var onPick: (NoteSuggestion) -> Void = { _ in }
    private(set) var suggestions: [NoteSuggestion] = []
    private(set) var selected = 0
    private var rows: [NSView] = []

    init() {
        super.init(frame: .zero)
        isHidden = true
        setAccessibilityRole(.list)
        setAccessibilityLabel("Notes")
    }

    required init?(coder: NSCoder) {
        nil
    }

    override var isFlipped: Bool {
        true
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
        layer.shadowOpacity = 0.14
        layer.shadowRadius = 6
        layer.shadowOffset = CGSize(width: 0, height: -2)
        for (index, row) in rows.enumerated() {
            row.layer?.backgroundColor = index == selected ? NSColor.controlAccentColor.withAlphaComponent(0.18).cgColor : NSColor.clear.cgColor
        }
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .arrow)
    }

    var selectedSuggestion: NoteSuggestion? {
        suggestions.indices.contains(selected) ? suggestions[selected] : nil
    }

    func show(_ suggestions: [NoteSuggestion], below caret: CGRect, in view: NSView) {
        guard suggestions.isEmpty == false else {
            hide()
            return
        }
        if self.suggestions != suggestions {
            self.suggestions = suggestions
            selected = 0
            rebuildRows()
        }
        if superview !== view {
            view.addSubview(self)
        } else {
            view.addSubview(self, positioned: .above, relativeTo: nil)
        }
        let size = CGSize(width: Self.width, height: CGFloat(suggestions.count) * Self.rowHeight + Self.inset * 2)
        let visible = view.visibleRect
        let x = max(min(caret.minX - 8, visible.maxX - size.width - 4), visible.minX + 4)
        let below = caret.maxY + 4
        let y = below + size.height > visible.maxY && caret.minY - size.height - 4 > visible.minY ? caret.minY - size.height - 4 : below
        frame = CGRect(origin: CGPoint(x: x, y: y), size: size)
        isHidden = false
        needsDisplay = true
    }

    func hide() {
        isHidden = true
        suggestions = []
        selected = 0
    }

    func moveSelection(by offset: Int) {
        guard suggestions.isEmpty == false else { return }
        selected = (selected + offset + suggestions.count) % suggestions.count
        needsDisplay = true
    }

    private func rebuildRows() {
        rows.forEach { $0.removeFromSuperview() }
        rows = suggestions.enumerated().map { index, suggestion in
            let row = NSView(frame: CGRect(x: Self.inset, y: Self.inset + CGFloat(index) * Self.rowHeight, width: Self.width - Self.inset * 2, height: Self.rowHeight))
            row.wantsLayer = true
            row.layer?.cornerRadius = 5
            let icon = NSImageView(image: NSImage(systemSymbolName: suggestion.isNew ? "plus" : "doc.text", accessibilityDescription: nil) ?? NSImage())
            icon.contentTintColor = .secondaryLabelColor
            icon.frame = CGRect(x: 8, y: 5, width: 16, height: 16)
            let title = NSTextField(labelWithString: suggestion.isNew ? "Link to “\(suggestion.name)”" : suggestion.name)
            title.font = .systemFont(ofSize: 13)
            title.textColor = suggestion.isNew ? .secondaryLabelColor : .labelColor
            title.lineBreakMode = .byTruncatingTail
            title.frame = CGRect(x: 30, y: 4, width: row.frame.width - 38, height: 18)
            row.addSubview(icon)
            row.addSubview(title)
            row.setAccessibilityElement(true)
            row.setAccessibilityRole(.button)
            row.setAccessibilityLabel(title.stringValue)
            addSubview(row)
            return row
        }
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        guard let index = rows.firstIndex(where: { $0.frame.contains(point) }) else { return }
        selected = index
        onPick(suggestions[index])
    }
}
