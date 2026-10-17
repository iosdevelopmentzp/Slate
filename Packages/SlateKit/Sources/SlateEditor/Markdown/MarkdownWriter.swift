import Foundation

package enum MarkdownWriter {

    package static func write(_ text: NSAttributedString) -> String {
        var rendered: [String] = []
        var previousList: ListFamily?
        for block in group(paragraphs(of: text)) {
            guard let first = block.first else { continue }
            let output: String?
            if first.block.kind.isList {
                let family = ListFamily.family(of: first.block.kind)
                let alternate = previousList.map { $0.kind == family && $0.alternate == false } ?? false
                output = ListWriter.write(block, alternate: alternate)
                previousList = output == nil ? previousList : ListFamily(kind: family, alternate: alternate)
            } else {
                output = render(block)
                if output?.isEmpty == false { previousList = nil }
            }
            if let output, output.isEmpty == false { rendered.append(output) }
        }
        guard rendered.isEmpty == false else { return "" }
        return rendered.joined(separator: "\n\n") + "\n"
    }

    static func paragraphs(of text: NSAttributedString) -> [WriterParagraph] {
        let string = text.string as NSString
        var result: [WriterParagraph] = []
        var start = 0
        while start <= string.length {
            let search = NSRange(location: start, length: string.length - start)
            let newline = string.range(of: "\n", options: .literal, range: search)
            let end = newline.location == NSNotFound ? string.length : newline.location
            let content = NSRange(location: start, length: end - start)
            let attributeIndex = content.length > 0 ? content.location : (newline.location == NSNotFound ? nil : newline.location)
            let block = attributeIndex.map { BlockAttributes(text.attributes(at: $0, effectiveRange: nil)) } ?? BlockAttributes()
            result.append(WriterParagraph(block: block, text: text.attributedSubstring(from: content)))
            guard newline.location != NSNotFound else { break }
            start = end + 1
        }
        return result
    }

    private static func group(_ paragraphs: [WriterParagraph]) -> [[WriterParagraph]] {
        var groups: [[WriterParagraph]] = []
        for paragraph in paragraphs where isEmpty(paragraph) == false {
            if let current = groups.last, let last = current.last, belongTogether(last.block, paragraph.block), sameListFamily(current, paragraph) {
                groups[groups.count - 1].append(paragraph)
            } else {
                groups.append([paragraph])
            }
        }
        return groups
    }

    private static func isEmpty(_ paragraph: WriterParagraph) -> Bool {
        guard paragraph.block.kind.isAttachment == false else { return false }
        if paragraph.block.kind.keepsLineBreaks { return paragraph.text.length == 0 }
        return paragraph.text.string.allSatisfy { $0.isWhitespace || $0 == RichText.lineBreak }
    }

    private static func sameListFamily(_ group: [WriterParagraph], _ next: WriterParagraph) -> Bool {
        guard next.block.kind.isList, next.block.indent == 0, let first = group.first, first.block.kind.isList else { return true }
        return ListFamily.family(of: first.block.kind) == ListFamily.family(of: next.block.kind)
    }

    private static func belongTogether(_ previous: BlockAttributes, _ next: BlockAttributes) -> Bool {
        if previous.kind.isList, next.kind.isList { return previous.group == next.group || next.indent > 0 }
        return previous.kind == .quote && next.kind == .quote && previous.group == next.group
    }

    private static func render(_ group: [WriterParagraph]) -> String? {
        guard let first = group.first else { return nil }
        switch first.block.kind {
        case .bullet, .numbered, .checklist:
            return ListWriter.write(group, alternate: false)
        case .quote:
            return group.map { InlineWriter.lines(of: $0.text).map { $0.isEmpty ? ">" : "> " + $0 }.joined(separator: "\n") }.joined(separator: "\n>\n")
        case .title:
            return heading(1, first.text)
        case .heading:
            return heading(2, first.text)
        case .subheading:
            return heading(3, first.text)
        case .body:
            return InlineWriter.lines(of: first.text).joined(separator: "\n")
        case .monospaced:
            return fence(first.text.string, language: first.block.language)
        case .raw:
            return first.text.string.replacingOccurrences(of: RichText.lineBreakString, with: "\n")
        case .image:
            return image(first.block)
        case .divider:
            return "---"
        case .table:
            return first.block.table?.markdown
        }
    }

    private static func heading(_ level: Int, _ text: NSAttributedString) -> String? {
        let flat = NSMutableAttributedString(attributedString: text)
        flat.mutableString.replaceOccurrences(of: RichText.lineBreakString, with: " ", options: .literal, range: NSRange(location: 0, length: flat.length))
        let line = InlineWriter.lines(of: flat).joined(separator: " ")
        guard line.isEmpty == false else { return nil }
        return String(repeating: "#", count: level) + " " + line
    }

    static func fence(_ text: String, language: String?) -> String {
        let code = text.replacingOccurrences(of: RichText.lineBreakString, with: "\n")
        let usesTildes = language?.contains("`") == true
        let mark: Character = usesTildes ? "~" : "`"
        let longest = longestRun(of: mark, in: code)
        let fence = String(repeating: mark, count: max(3, longest + 1))
        return fence + (language ?? "") + "\n" + code + (code.isEmpty ? "" : "\n") + fence
    }

    private static func longestRun(of mark: Character, in text: String) -> Int {
        var longest = 0
        var current = 0
        for character in text {
            current = character == mark ? current + 1 : 0
            longest = max(longest, current)
        }
        return longest
    }

    private static func image(_ block: BlockAttributes) -> String? {
        guard let path = block.imagePath, path.isEmpty == false else { return nil }
        let alt = InlineWriter.escapeLabel(block.imageAlt ?? "")
        return "![\(alt)](\(InlineWriter.destination(path)))"
    }
}
