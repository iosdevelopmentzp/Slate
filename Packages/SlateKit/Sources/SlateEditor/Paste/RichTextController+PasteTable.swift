import AppKit

extension RichTextController {
    func pasteAsTable(from pasteboard: NSPasteboard) {
        guard let text = pasteboard.string(forType: .string) else { return }
        if TableMarkdown.looksLikeTable(text) {
            insertFragment(MarkdownReader.read(text.trimmingCharacters(in: .whitespacesAndNewlines)))
            return
        }
        guard let model = TableSeparatedText.model(from: text) else {
            insertPlain(text)
            return
        }
        insertTable(model, editing: false)
    }
}
