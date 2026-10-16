import AppKit

final class LinkPopover: NSObject, NSTextFieldDelegate {
    enum Result {
        case set(String)
        case remove
    }

    private let popover = NSPopover()
    private let field = NSTextField()
    private let completion: (Result) -> Void
    private var isDone = false

    init(url: String, canRemove: Bool, completion: @escaping (Result) -> Void) {
        self.completion = completion
        super.init()
        field.stringValue = url
        field.placeholderString = "https://example.com"
        field.delegate = self
        field.bezelStyle = .roundedBezel
        field.setAccessibilityLabel("Link address")
        let apply = NSButton(title: "Add Link", target: self, action: #selector(applyLink))
        apply.keyEquivalent = "\r"
        apply.bezelStyle = .push
        let label = NSTextField(labelWithString: "Link")
        label.font = .systemFont(ofSize: NSFont.smallSystemFontSize, weight: .semibold)
        label.textColor = .secondaryLabelColor
        var buttons: [NSView] = []
        if canRemove {
            apply.title = "Save"
            let remove = NSButton(title: "Remove Link", target: self, action: #selector(removeLink))
            remove.bezelStyle = .push
            buttons.append(remove)
        }
        buttons.append(apply)
        let row = NSStackView(views: buttons)
        row.orientation = .horizontal
        row.spacing = 8
        let stack = NSStackView(views: [label, field, row])
        stack.orientation = .vertical
        stack.alignment = .trailing
        stack.spacing = 8
        stack.edgeInsets = NSEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        field.widthAnchor.constraint(equalToConstant: 300).isActive = true
        let controller = NSViewController()
        controller.view = stack
        popover.contentViewController = controller
        popover.behavior = .transient
    }

    func show(relativeTo rect: NSRect, of view: NSView) {
        popover.show(relativeTo: rect, of: view, preferredEdge: .maxY)
        popover.contentViewController?.view.window?.makeFirstResponder(field)
    }

    @objc private func applyLink() {
        finish(.set(field.stringValue))
    }

    @objc private func removeLink() {
        finish(.remove)
    }

    private func finish(_ result: Result) {
        guard isDone == false else { return }
        isDone = true
        popover.close()
        completion(result)
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            popover.close()
            return true
        }
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            applyLink()
            return true
        }
        return false
    }
}
