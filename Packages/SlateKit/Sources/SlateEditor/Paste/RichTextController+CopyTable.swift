import AppKit

extension RichTextController {
    func copyTable(_ attachment: TableAttachment, asText: Bool) {
        copyTable(attachment, asText: asText, to: PasteboardBridge.general)
    }

    func copyTable(_ attachment: TableAttachment, asText: Bool, to pasteboard: NSPasteboard) {
        let markdown = TableBlock(model: attachment.model, source: attachment.block.source).markdown
        PasteboardReader.write(markdown: markdown, plain: asText ? TableSeparatedText.text(of: attachment.model) : markdown, to: pasteboard)
    }
}
