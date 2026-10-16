import AppKit
import Testing
@testable import SlateEditor

final class EditorHarness {
    let controller: EditorController
    let window: NSWindow

    init(text: String = "", configuration: EditorConfiguration = .standard, resolveImage: @escaping (String) -> URL? = { _ in nil }) {
        controller = EditorController(configuration: configuration)
        controller.resolveImage = resolveImage
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 800, height: 600), styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        controller.container.frame = NSRect(x: 0, y: 0, width: 800, height: 600)
        window.contentView = controller.container
        controller.textView.frame = NSRect(x: 0, y: 0, width: 800, height: 600)
        controller.setText(text)
        layout()
    }

    var textView: MarkdownTextView { controller.textView }

    func layout() {
        controller.container.layoutSubtreeIfNeeded()
        controller.textView.textLayoutManager?.textViewportLayoutController.layoutViewport()
        controller.textView.displayIfNeeded()
    }

    func type(_ string: String, at location: Int) {
        textView.setSelectedRange(NSRange(location: location, length: 0))
        textView.insertText(string, replacementRange: NSRange(location: location, length: 0))
        layout()
    }

    func paragraph(at location: Int) -> NSAttributedString? {
        guard let storage = textView.textContentStorage,
              let start = storage.location(storage.documentRange.location, offsetBy: location) else { return nil }
        var result: NSAttributedString?
        storage.enumerateTextElements(from: start, options: []) { element in
            result = (element as? NSTextParagraph)?.attributedString
            return false
        }
        return result
    }

    func font(at location: Int) -> NSFont? {
        paragraph(at: location)?.attribute(.font, at: 0, effectiveRange: nil) as? NSFont
    }

    static func fixture(_ name: String) throws -> String {
        let url = try #require(Bundle.module.url(forResource: name, withExtension: "md", subdirectory: "Fixtures"))
        return try String(contentsOf: url, encoding: .utf8)
    }
}
