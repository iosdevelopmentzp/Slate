import AppKit

final class PasteAsCodeBar: NSView {
    var onAccept: () -> Void = {}
    var onDismiss: () -> Void = {}

    private let label = NSTextField(labelWithString: "")
    private let accept = NSButton(title: "Paste as code", target: nil, action: nil)
    private let dismiss = NSButton(title: "Keep as text", target: nil, action: nil)

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.1).cgColor
        label.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        label.textColor = .secondaryLabelColor
        for button in [accept, dismiss] {
            button.bezelStyle = .accessoryBarAction
            button.controlSize = .small
            button.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
            button.target = self
        }
        accept.action = #selector(acceptClicked)
        accept.toolTip = "Enter"
        dismiss.action = #selector(dismissClicked)
        dismiss.toolTip = "Esc"
        let stack = NSStackView(views: [label, NSView(), accept, dismiss])
        stack.orientation = .horizontal
        stack.spacing = 8
        stack.edgeInsets = NSEdgeInsets(top: 4, left: 16, bottom: 4, right: 12)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        nil
    }

    func show(language: String) {
        let name = language == "plain" ? "" : " (\(Self.displayName(language)))"
        label.stringValue = "This looks like code\(name). Paste it as a code block?"
    }

    private static func displayName(_ language: String) -> String {
        switch language {
        case "objc": "Objective-C"
        case "json": "JSON"
        case "yaml": "YAML"
        case "bash": "shell"
        default: language.prefix(1).uppercased() + language.dropFirst()
        }
    }

    @objc private func acceptClicked() {
        onAccept()
    }

    @objc private func dismissClicked() {
        onDismiss()
    }
}
