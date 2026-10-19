import AppKit

extension RichTextController {
    static let jsonBlock = BlockAttributes(kind: .monospaced, language: "json")

    func formatJSON() {
        let selection = textView.selectedRange()
        guard let target = selection.length > 0 ? selection : codeBlockContent(at: selection.location), target.length > 0 else {
            handlers.notice("Select the JSON to format")
            return
        }
        let paragraphs = paragraphRanges(covering: target)
        guard let first = paragraphs.first, let last = paragraphs.last, paragraphs.allSatisfy({ block(at: $0.location).kind.isAttachment == false }) else {
            handlers.notice("Select only text to format JSON")
            return
        }
        guard let pretty = CodeText.formattedJSON(string.substring(with: target)) else {
            handlers.notice("The selection is not valid JSON")
            return
        }
        let code = pretty.replacingOccurrences(of: "\n", with: RichText.lineBreakString)
        let firstBlock = block(at: first.location)
        if paragraphs.count == 1, firstBlock.kind.keepsLineBreaks {
            formatInsideCodeBlock(first, target: target, code: code, block: firstBlock)
            return
        }
        let lastContent = contentRange(of: last)
        let before = NSRange(location: first.location, length: target.location - first.location)
        let after = NSRange(location: NSMaxRange(target), length: max(NSMaxRange(lastContent) - NSMaxRange(target), 0))
        let result = NSMutableAttributedString()
        if isBlank(before) == false {
            result.append(storage.attributedSubstring(from: before))
            result.append(styled("\n", block: firstBlock))
        }
        result.append(styled(code, block: Self.jsonBlock))
        let caret = result.length
        var endBlock = Self.jsonBlock
        if isBlank(after) == false {
            endBlock = block(at: last.location)
            result.append(styled("\n", block: Self.jsonBlock))
            result.append(storage.attributedSubstring(from: after))
        }
        if NSMaxRange(lastContent) < NSMaxRange(last) {
            result.append(styled("\n", block: endBlock))
        }
        let union = NSUnionRange(first, last)
        replace(union, with: result, selection: NSRange(location: union.location + caret, length: 0))
    }

    private func formatInsideCodeBlock(_ paragraph: NSRange, target: NSRange, code: String, block: BlockAttributes) {
        let content = contentRange(of: paragraph)
        let outside = [NSRange(location: content.location, length: target.location - content.location), NSRange(location: NSMaxRange(target), length: max(NSMaxRange(content) - NSMaxRange(target), 0))]
        if outside.allSatisfy(isBlank) {
            replace(content, with: styled(code, block: Self.jsonBlock), selection: NSRange(location: content.location + (code as NSString).length, length: 0))
        } else {
            replace(target, with: styled(code, block: block), selection: NSRange(location: target.location + (code as NSString).length, length: 0))
        }
    }

    private func codeBlockContent(at location: Int) -> NSRange? {
        guard block(at: location).kind == .monospaced else { return nil }
        return contentRange(of: paragraphRange(at: location))
    }

    private func isBlank(_ range: NSRange) -> Bool {
        range.length <= 0 || string.substring(with: range).allSatisfy { $0.isWhitespace }
    }
}
