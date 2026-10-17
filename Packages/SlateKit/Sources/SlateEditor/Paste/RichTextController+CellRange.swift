import AppKit

extension RichTextController {
    func copyCells(_ attachment: TableAttachment, range: TableCellRange) {
        copyCells(attachment, range: range, to: PasteboardBridge.general)
    }

    func copyCells(_ attachment: TableAttachment, range: TableCellRange, to pasteboard: NSPasteboard) {
        let slice = attachment.model.slice(range)
        if range.isSingle {
            let markdown = attachment.model.cell(range.anchor).markdown
            PasteboardReader.write(markdown: markdown, plain: TableSeparatedText.text(of: slice), to: pasteboard)
            return
        }
        PasteboardReader.write(markdown: TableMarkdown.render(slice), plain: TableSeparatedText.text(of: slice), to: pasteboard)
    }

    func pasteIntoCells(_ view: TableBlockView) {
        pasteIntoCells(view, from: PasteboardBridge.general)
    }

    func pasteIntoCells(_ view: TableBlockView, from pasteboard: NSPasteboard) {
        guard let source = Self.cellModel(from: pasteboard) else { return }
        view.paste(source)
    }

    static func cellModel(from pasteboard: NSPasteboard) -> TableModel? {
        if let markdown = pasteboard.string(forType: PasteboardReader.markdownType), let model = TableMarkdown.parse(markdown) {
            return model
        }
        if let markdown = pasteboard.string(forType: PasteboardReader.markdownType), markdown.contains("\n") == false {
            return TableModel(columns: [TableColumn()], header: [TableCell(markdown)], rows: [])
        }
        guard let text = pasteboard.string(forType: .string)?.trimmingCharacters(in: .newlines), text.isEmpty == false else { return nil }
        if TableMarkdown.looksLikeTable(text), let model = TableMarkdown.parse(text) {
            return model
        }
        if let model = TableSeparatedText.model(from: text) {
            return model
        }
        let cells = text.components(separatedBy: .newlines).map { TableCell(TableCellText.markdown(of: NSAttributedString(string: $0.trimmingCharacters(in: .whitespaces)))) }
        return TableModel(columns: [TableColumn()], header: [cells[0]], rows: cells.dropFirst().map { [$0] })
    }
}
