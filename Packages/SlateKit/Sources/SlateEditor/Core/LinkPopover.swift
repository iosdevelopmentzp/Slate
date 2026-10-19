import AppKit

final class LinkPopover: NSObject, NSPopoverDelegate, NSComboBoxDelegate {
    enum Result: Equatable {
        case set(text: String?, href: String)
        case remove
        case cancel
    }

    static let fieldWidth: CGFloat = 280

    private let popover = NSPopover()
    private let textField = NSTextField()
    private let addressField = NSComboBox()
    private let original: String?
    private let editsText: Bool
    private let completion: (Result) -> Void
    private var notes: [String] = []
    private var isDone = false

    init(text: String?, href: String?, suggestion: String, completion: @escaping (Result) -> Void) {
        original = href
        editsText = text != nil
        self.completion = completion
        super.init()
        textField.stringValue = text ?? ""
        textField.placeholderString = "Text to show"
        textField.bezelStyle = .roundedBezel
        textField.delegate = self
        textField.setAccessibilityLabel("Link text")
        addressField.stringValue = href.map(LinkAddress.display) ?? suggestion
        addressField.placeholderString = "https://example.com or a note name"
        addressField.completes = true
        addressField.numberOfVisibleItems = 8
        addressField.delegate = self
        addressField.setAccessibilityLabel("Link address")
        for field in [textField, addressField] as [NSTextField] {
            field.widthAnchor.constraint(equalToConstant: Self.fieldWidth).isActive = true
        }
        let hint = NSTextField(wrappingLabelWithString: "A web address, or the name of a note in Slate.")
        hint.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        hint.textColor = .secondaryLabelColor
        let grid = NSGridView(views: [
            [Self.label("Text"), textField],
            [Self.label("Link to"), addressField],
            [NSGridCell.emptyContentView, hint],
        ])
        grid.rowSpacing = 8
        grid.columnSpacing = 8
        grid.rowAlignment = .firstBaseline
        grid.column(at: 0).xPlacement = .trailing
        grid.row(at: 0).isHidden = editsText == false
        let stack = NSStackView(views: [grid, buttons()])
        stack.orientation = .vertical
        stack.alignment = .trailing
        stack.spacing = 12
        stack.edgeInsets = NSEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)
        let controller = NSViewController()
        controller.view = stack
        popover.contentViewController = controller
        popover.behavior = .transient
        popover.delegate = self
    }

    private static func label(_ title: String) -> NSTextField {
        let label = NSTextField(labelWithString: title)
        label.textColor = .secondaryLabelColor
        return label
    }

    private func buttons() -> NSStackView {
        let save = NSButton(title: original == nil ? "Add Link" : "Save", target: self, action: #selector(saveLink))
        save.keyEquivalent = "\r"
        let cancel = NSButton(title: "Cancel", target: self, action: #selector(cancel))
        var views: [NSView] = [cancel, save]
        if original != nil {
            let remove = NSButton(title: "Remove Link", target: self, action: #selector(removeLink))
            views.insert(remove, at: 0)
        }
        let row = NSStackView(views: views)
        row.orientation = .horizontal
        row.spacing = 8
        return row
    }

    func setNotes(_ names: [String]) {
        notes = names
        addressField.removeAllItems()
        addressField.addItems(withObjectValues: names)
    }

    func show(relativeTo rect: NSRect, of view: NSView) {
        popover.appearance = view.effectiveAppearance
        popover.animates = false
        popover.show(relativeTo: rect, of: view, preferredEdge: .maxY)
        focusField()
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            focusField()
        }
    }

    private func focusField() {
        guard isDone == false, let window = popover.contentViewController?.view.window else { return }
        let first: NSTextField = editsText == false || addressField.stringValue.isEmpty || textField.stringValue.isEmpty == false ? addressField : textField
        window.makeKeyAndOrderFront(nil)
        if (window.firstResponder as? NSTextView)?.delegate as? NSTextField !== first {
            window.makeFirstResponder(first)
        }
    }

    func popoverDidShow(_ notification: Notification) {
        focusField()
    }

    @objc private func saveLink() {
        let raw = addressField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let href: String?
        if let original, raw == LinkAddress.display(original) {
            href = original
        } else {
            href = LinkAddress.href(for: raw, notes: notes)
        }
        guard let href else {
            finish(original == nil ? .cancel : .remove)
            return
        }
        guard editsText else {
            finish(.set(text: nil, href: href))
            return
        }
        let text = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        finish(.set(text: text.isEmpty ? LinkAddress.display(href) : text, href: href))
    }

    @objc private func removeLink() {
        finish(.remove)
    }

    @objc private func cancel() {
        finish(.cancel)
    }

    private func finish(_ result: Result) {
        guard isDone == false else { return }
        isDone = true
        popover.close()
        completion(result)
    }

    func popoverDidClose(_ notification: Notification) {
        finish(.cancel)
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        switch commandSelector {
        case #selector(NSResponder.cancelOperation(_:)):
            finish(.cancel)
            return true
        case #selector(NSResponder.insertNewline(_:)):
            saveLink()
            return true
        default:
            return false
        }
    }
}
