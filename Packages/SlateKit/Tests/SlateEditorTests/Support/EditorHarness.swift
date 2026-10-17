import AppKit
import Testing
@testable import SlateEditor

final class EditorHarness {
    let controller: RichTextController
    let window: NSWindow
    let commands = EditorCommands()
    private(set) var published: [String] = []

    init(markdown: String = "", configuration: EditorConfiguration = .standard, resolveImage: @escaping (String) -> URL? = { _ in nil }) {
        controller = RichTextController(configuration: configuration)
        controller.handlers = EditorHandlers(resolveImage: resolveImage)
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 800, height: 600), styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        controller.scrollView.frame = NSRect(x: 0, y: 0, width: 800, height: 600)
        window.contentView = controller.scrollView
        controller.textView.frame = NSRect(x: 0, y: 0, width: 800, height: 600)
        controller.commands = commands
        controller.onMarkdownChange = { [weak self] value in self?.published.append(value) }
        controller.setMarkdown(markdown)
        window.makeFirstResponder(controller.textView)
        layout()
    }

    var textView: RichTextView { controller.textView }

    var markdown: String {
        controller.flush()
        return controller.markdown
    }

    var text: String { controller.storage.string }

    func layout() {
        controller.textView.textLayoutManager?.textViewportLayoutController.layoutViewport()
        hostTables()
        controller.textView.displayIfNeeded()
    }

    private func hostTables() {
        controller.storage.enumerateAttribute(.attachment, in: NSRange(location: 0, length: controller.storage.length)) { value, _, _ in
            guard let table = value as? TableAttachment, table.loadedView?.superview == nil else { return }
            let view = table.view()
            view.frame = table.bounds(in: textView.textContainer, proposed: textView.bounds)
            textView.addSubview(view)
        }
    }

    func select(_ location: Int, _ length: Int = 0) {
        textView.setSelectedRange(NSRange(location: location, length: length))
    }

    func caret(after needle: String) {
        let range = (text as NSString).range(of: needle)
        select(NSMaxRange(range))
    }

    func selectText(_ needle: String) {
        let range = (text as NSString).range(of: needle)
        select(range.location, range.length)
    }

    func type(_ string: String) {
        for character in string {
            if character == "\n" {
                textView.doCommand(by: #selector(NSResponder.insertNewline(_:)))
            } else {
                textView.insertText(String(character), replacementRange: textView.selectedRange())
            }
        }
        layout()
    }

    func undoStep(_ body: () -> Void) {
        let undo = controller.undoManager
        undo.groupsByEvent = false
        undo.beginUndoGrouping()
        body()
        undo.endUndoGrouping()
    }

    func command(_ selector: Selector) {
        textView.doCommand(by: selector)
        layout()
    }

    func block(at location: Int) -> BlockAttributes {
        controller.block(at: location)
    }

    func font(at location: Int) -> NSFont? {
        controller.storage.attribute(.font, at: location, effectiveRange: nil) as? NSFont
    }

    func table(at index: Int = 0) -> TableAttachment? {
        var tables: [TableAttachment] = []
        controller.storage.enumerateAttribute(.attachment, in: NSRange(location: 0, length: controller.storage.length)) { value, _, _ in
            if let table = value as? TableAttachment { tables.append(table) }
        }
        return index < tables.count ? tables[index] : nil
    }

    static func fixture(_ name: String) throws -> String {
        let url = try #require(Bundle.module.url(forResource: name, withExtension: "md", subdirectory: "Fixtures"))
        return try String(contentsOf: url, encoding: .utf8)
    }
}
