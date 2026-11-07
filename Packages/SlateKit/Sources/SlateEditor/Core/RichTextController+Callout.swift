import AppKit

extension RichTextController {

    func makeCallout(_ kind: CalloutKind) {
        let selection = textView.selectedRange()
        let current = block(at: selection.location)
        if current.callout != nil {
            changeCallout(of: current.group, to: kind)
            return
        }
        let paragraphs = paragraphRanges(covering: selection).filter { block(at: $0.location).kind.isAttachment == false }
        guard let first = paragraphs.first, let last = paragraphs.last else { return }
        let union = NSUnionRange(first, last)
        let group = makeGroup()
        let body = BlockAttributes(kind: .quote, group: group, callout: kind.marker)
        var header = body
        header.isCalloutHeader = true
        let result = NSMutableAttributedString(attributedString: styled("\n", block: header))
        for paragraph in paragraphs {
            var text = storage.attributedSubstring(from: paragraph)
            if block(at: paragraph.location).kind.keepsLineBreaks {
                let split = NSMutableAttributedString(attributedString: text)
                split.mutableString.replaceOccurrences(of: RichText.lineBreakString, with: "\n", options: .literal, range: NSRange(location: 0, length: split.length))
                text = split
            }
            result.append(retagged(text, as: body))
        }
        if NSMaxRange(union) == storage.length, result.string.hasSuffix("\n") == false {
            result.append(styled("\n", block: BlockAttributes()))
        }
        replace(union, with: result, selection: NSRange(location: union.location + 1 + max(selection.location - union.location, 0), length: selection.length))
    }

    private func changeCallout(of group: Int, to kind: CalloutKind) {
        let selection = textView.selectedRange()
        var location = paragraphRange(at: selection.location).location
        while location > 0, sameCallout(at: location - 1, group: group) {
            location = paragraphRange(at: location - 1).location
        }
        var paragraphs: [NSRange] = []
        while location < storage.length, sameCallout(at: location, group: group) {
            let paragraph = paragraphRange(at: location)
            paragraphs.append(paragraph)
            location = NSMaxRange(paragraph)
        }
        guard let first = paragraphs.first, let last = paragraphs.last else { return }
        let union = NSUnionRange(first, last)
        let result = NSMutableAttributedString()
        for paragraph in paragraphs {
            var target = block(at: paragraph.location)
            target.callout = kind.marker
            result.append(retagged(storage.attributedSubstring(from: paragraph), as: target))
        }
        replace(union, with: result, selection: selection)
    }

    private func sameCallout(at location: Int, group: Int) -> Bool {
        let other = block(at: location)
        return other.callout != nil && other.group == group
    }
}
