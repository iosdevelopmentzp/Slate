import AppKit

extension RichTextController {

    func setHighlight(_ color: HighlightColor?) {
        recolor(isSet: { color != nil && $0.highlight == color }, change: { style, isSet in style.highlight = isSet ? nil : color })
    }

    func setTextColor(_ color: TextColor?) {
        recolor(isSet: { color != nil && $0.textColor == color }, change: { style, isSet in style.textColor = isSet ? nil : color })
    }

    private func recolor(isSet: (InlineStyle) -> Bool, change: (inout InlineStyle, Bool) -> Void) {
        let selection = textView.selectedRange()
        guard currentBlock.kind.keepsLineBreaks == false else { return }
        if selection.length == 0 {
            var current = pendingInline ?? InlineStyle(rawValue: textView.typingAttributes[.slateInline] as? Int ?? 0)
            change(&current, isSet(current))
            pendingInline = current
            updateTypingAttributes()
            updateState()
            return
        }
        let result = NSMutableAttributedString(attributedString: storage.attributedSubstring(from: selection))
        let whole = NSRange(location: 0, length: result.length)
        let isColourable = { (range: NSRange) in
            let text = (result.string as NSString).substring(with: range)
            return text.contains(Character(RichText.attachmentString)) == false && BlockAttributes(result.attributes(at: range.location, effectiveRange: nil)).kind.keepsLineBreaks == false
        }
        var all = true
        result.enumerateAttributes(in: whole) { attributes, range, stop in
            let text = (result.string as NSString).substring(with: range)
            guard isColourable(range), text.allSatisfy({ $0.isWhitespace || $0 == RichText.lineBreak }) == false else { return }
            if isSet(InlineStyle(rawValue: attributes[.slateInline] as? Int ?? 0)) == false {
                all = false
                stop.pointee = true
            }
        }
        result.enumerateAttributes(in: whole) { attributes, range, _ in
            guard isColourable(range) else { return }
            var inline = InlineStyle(rawValue: attributes[.slateInline] as? Int ?? 0)
            change(&inline, all)
            if inline.isEmpty {
                result.removeAttribute(.slateInline, range: range)
            } else {
                result.addAttribute(.slateInline, value: inline.rawValue, range: range)
            }
        }
        replace(selection, with: result, selection: selection)
    }
}
