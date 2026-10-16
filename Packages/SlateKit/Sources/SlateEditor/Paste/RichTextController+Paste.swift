import AppKit

extension RichTextController {

    func copySelection(to pasteboard: NSPasteboard) -> Bool {
        let selection = textView.selectedRange()
        guard selection.length > 0 else { return false }
        let fragment = storage.attributedSubstring(from: selection)
        var markdown = MarkdownWriter.write(fragment)
        if markdown.hasSuffix("\n") { markdown.removeLast() }
        let plain = fragment.string
            .replacingOccurrences(of: RichText.lineBreakString, with: "\n")
            .replacingOccurrences(of: RichText.attachmentString, with: "")
        PasteboardReader.write(markdown: markdown, plain: plain, to: pasteboard)
        return true
    }

    func paste(from pasteboard: NSPasteboard) {
        guard let content = PasteboardReader.read(pasteboard) else { return }
        switch content {
        case .markdown(let markdown):
            insertFragment(MarkdownReader.read(markdown))
        case .files(let urls):
            handlers.pasteFiles(urls)
        case .image(let data, let fileExtension):
            handlers.pasteImage(data, fileExtension)
        case .html(let data):
            if let fragment = HTMLImport.fragment(from: data) {
                insertFragment(fragment)
            } else if let text = pasteboard.string(forType: .string) {
                insertPlain(text)
            }
        case .text(let text):
            insertPlain(text)
        }
    }

    func drop(_ pasteboard: NSPasteboard, at point: CGPoint) -> Bool {
        guard let content = PasteboardReader.read(pasteboard) else { return false }
        let index = textView.characterIndexForInsertion(at: point)
        switch content {
        case .files(let urls):
            textView.setSelectedRange(NSRange(location: min(index, storage.length), length: 0))
            handlers.pasteFiles(urls)
            return true
        case .image(let data, let fileExtension):
            textView.setSelectedRange(NSRange(location: min(index, storage.length), length: 0))
            handlers.pasteImage(data, fileExtension)
            return true
        default:
            return false
        }
    }

    func insertPlain(_ text: String) {
        let block = currentBlock
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
        let separator = block.kind.keepsLineBreaks ? RichText.lineBreakString : "\n"
        let joined = normalized.replacingOccurrences(of: "\n", with: separator)
        let selection = textView.selectedRange()
        let inline = InlineStyle(rawValue: textView.typingAttributes[.slateInline] as? Int ?? 0)
        let inserted = NSAttributedString(string: joined, attributes: styler.attributes(block: block.kind.isAttachment ? BlockAttributes() : block, inline: inline, href: nil))
        replace(selection, with: inserted, selection: NSRange(location: selection.location + inserted.length, length: 0))
    }

    func insertFragment(_ fragment: NSAttributedString) {
        guard fragment.length > 0 else { return }
        let paragraphs = MarkdownWriter.paragraphs(of: fragment)
        if paragraphs.count == 1, let only = paragraphs.first, only.block.kind.isAttachment == false {
            let block = currentBlock
            let text = NSMutableAttributedString(attributedString: retagged(only.text, as: block.kind.isAttachment ? BlockAttributes() : block))
            if block.kind.keepsLineBreaks {
                text.removeAttribute(.slateInline, range: NSRange(location: 0, length: text.length))
                text.removeAttribute(.slateHref, range: NSRange(location: 0, length: text.length))
            }
            restyle(text, range: NSRange(location: 0, length: text.length))
            let selection = textView.selectedRange()
            replace(selection, with: text, selection: NSRange(location: selection.location + text.length, length: 0))
            return
        }
        let selection = textView.selectedRange()
        if selection.length > 0 {
            replace(selection, with: NSAttributedString(), selection: NSRange(location: selection.location, length: 0))
        }
        insertBlocks(fragment)
    }
}
