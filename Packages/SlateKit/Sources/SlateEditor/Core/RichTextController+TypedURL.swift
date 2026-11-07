import AppKit

extension RichTextController {

    func linkTypedURL(endingAt location: Int) {
        guard location > 0, location <= storage.length, multiCaret.isActive == false else { return }
        let block = block(at: location - 1)
        guard block.kind.keepsLineBreaks == false, block.kind.isAttachment == false else { return }
        let paragraph = paragraphRange(at: location - 1)
        let head = NSRange(location: paragraph.location, length: location - paragraph.location)
        let text = string.substring(with: head)
        guard let found = BareURL.ranges(in: text).last else { return }
        let range = NSRange(location: head.location + found.location, length: found.length)
        let trailing = string.substring(with: NSRange(location: NSMaxRange(range), length: location - NSMaxRange(range)))
        guard trailing.allSatisfy({ $0.isWhitespace == false }) else { return }
        var isFree = true
        storage.enumerateAttributes(in: range) { attributes, _, stop in
            let inline = InlineStyle(rawValue: attributes[.slateInline] as? Int ?? 0)
            if attributes[.slateHref] != nil || inline.contains(.code) {
                isFree = false
                stop.pointee = true
            }
        }
        guard isFree else { return }
        let linked = NSMutableAttributedString(attributedString: storage.attributedSubstring(from: range))
        let whole = NSRange(location: 0, length: linked.length)
        linked.addAttribute(.slateHref, value: string.substring(with: range), range: whole)
        linked.addAttribute(.slateBareURL, value: true, range: whole)
        restyle(linked, range: whole)
        replace(range, with: linked, selection: textView.selectedRange())
    }

    func insertBareURL(_ url: String, at selection: NSRange) {
        var attributes = styler.attributes(block: currentBlock, inline: [], href: url)
        attributes[.slateBareURL] = true
        let inserted = NSAttributedString(string: url, attributes: attributes)
        replace(selection, with: inserted, selection: NSRange(location: selection.location + inserted.length, length: 0))
    }
}
