import AppKit

extension RichTextController {

    func pasteURL(from pasteboard: NSPasteboard) -> Bool {
        guard pasteboard.string(forType: PasteboardReader.markdownType) == nil,
              let text = pasteboard.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines),
              text.looksLikeURL, text.lowercased().hasPrefix("file:") == false,
              currentBlock.kind.keepsLineBreaks == false, currentBlock.kind.isAttachment == false else { return false }
        let selection = textView.selectedRange()
        if selection.length > 0 {
            guard LinkAddress.editableText(string.substring(with: selection)) != nil else { return false }
            applyLink(.set(text: nil, href: text), to: selection)
            return true
        }
        if let title = LinkTitle.short(for: text) {
            applyLink(.set(text: title, href: text), to: selection)
        } else {
            insertBareURL(text, at: selection)
        }
        return true
    }
}
