import Foundation
import Markdown

package enum MarkdownReader {

    package static func read(_ markdown: String) -> NSMutableAttributedString {
        let source = markdown.replacingOccurrences(of: "\r\n", with: "\n")
        let lines = source.components(separatedBy: "\n")
        let document = Document(parsing: source, options: [.disableSmartOpts])
        var builder = RichTextBuilder()
        var nextLine = 1
        for child in document.children {
            guard let range = child.range else { continue }
            let first = range.lowerBound.line
            let last = max(range.upperBound.line, first)
            if first > nextLine {
                appendGap(lines, from: nextLine, to: first - 1, into: &builder)
            }
            append(child, lines: lines, first: first, last: last, into: &builder)
            nextLine = max(nextLine, last + 1)
        }
        if nextLine <= lines.count {
            appendGap(lines, from: nextLine, to: lines.count, into: &builder)
        }
        return builder.result
    }

    private static func appendGap(_ lines: [String], from first: Int, to last: Int, into builder: inout RichTextBuilder) {
        var start = first
        var end = last
        while start <= end, isBlank(lines[start - 1]) { start += 1 }
        while end >= start, isBlank(lines[end - 1]) { end -= 1 }
        guard start <= end else { return }
        appendRaw(lines, first: start, last: end, into: &builder)
    }

    private static func isBlank(_ line: String) -> Bool {
        line.allSatisfy { $0 == " " || $0 == "\t" }
    }

    private static func appendRaw(_ lines: [String], first: Int, last: Int, into builder: inout RichTextBuilder) {
        var last = min(last, lines.count)
        while last > first, isBlank(lines[last - 1]) { last -= 1 }
        let text = lines[(first - 1)...(min(last, lines.count) - 1)].joined(separator: RichText.lineBreakString)
        builder.append(NSAttributedString(string: text), block: BlockAttributes(kind: .raw))
    }

    private static func append(_ markup: Markup, lines: [String], first: Int, last: Int, into builder: inout RichTextBuilder) {
        let source = lines[(first - 1)...(min(last, lines.count) - 1)].joined(separator: "\n")
        guard let blocks = convert(markup, source: source, lines: SourceLines(lines: lines), builder: &builder) else {
            appendRaw(lines, first: first, last: last, into: &builder)
            return
        }
        for block in blocks {
            builder.append(block.text, block: block.attributes)
        }
    }

    private static func convert(_ markup: Markup, source: String, lines: SourceLines, builder: inout RichTextBuilder) -> [ReadBlock]? {
        switch markup {
        case let heading as Heading:
            let kinds: [Int: BlockKind] = [1: .title, 2: .heading, 3: .subheading]
            guard let kind = kinds[heading.level], let text = InlineReader.read(heading.children, source: lines) else { return nil }
            return [ReadBlock(text: text, attributes: BlockAttributes(kind: kind))]
        case let paragraph as Paragraph:
            return convert(paragraph, source: source, lines: lines)
        case let code as CodeBlock:
            var text = code.code
            if text.hasSuffix("\n") { text.removeLast() }
            let language = code.language.flatMap { $0.isEmpty ? nil : $0 }
            return [ReadBlock(text: NSAttributedString(string: text.replacingOccurrences(of: "\n", with: RichText.lineBreakString)), attributes: BlockAttributes(kind: .monospaced, language: language))]
        case is Table:
            guard let model = TableMarkdown.parse(source), TableCellText.isSupported(model) else { return nil }
            let block = BlockAttributes(kind: .table, table: TableBlock(model: model, source: source))
            return [ReadBlock(text: NSAttributedString(string: RichText.attachmentString), attributes: block)]
        case is ThematicBreak:
            return [ReadBlock(text: NSAttributedString(string: RichText.attachmentString), attributes: BlockAttributes(kind: .divider))]
        case let quote as BlockQuote:
            let group = builder.nextGroup()
            var blocks: [ReadBlock] = []
            for child in quote.children {
                guard let paragraph = child as? Paragraph, isPlainParagraph(paragraph), let text = InlineReader.read(paragraph.children, source: lines) else { return nil }
                blocks.append(ReadBlock(text: text, attributes: BlockAttributes(kind: .quote, group: group)))
            }
            return blocks.isEmpty ? nil : blocks
        case let list as UnorderedList:
            return ListReader.read(list, indent: 0, group: builder.nextGroup(), source: lines)
        case let list as OrderedList:
            return ListReader.read(list, indent: 0, group: builder.nextGroup(), source: lines)
        default:
            return nil
        }
    }

    private static func convert(_ paragraph: Paragraph, source: String, lines: SourceLines) -> [ReadBlock]? {
        guard source.contains("[^") == false else { return nil }
        let children = Array(paragraph.children)
        if children.count == 1, let image = children.first as? Image {
            return imageBlock(image).map { [$0] }
        }
        if let text = InlineReader.read(children, source: lines) {
            return [ReadBlock(text: text, attributes: BlockAttributes(kind: .body))]
        }
        return splitAtImageLines(children, lines: lines)
    }

    private static func imageBlock(_ image: Image) -> ReadBlock? {
        guard image.title == nil, let path = image.source, path.isEmpty == false else { return nil }
        let alt = image.plainText
        return ReadBlock(text: NSAttributedString(string: RichText.attachmentString), attributes: BlockAttributes(kind: .image, imagePath: path, imageAlt: alt.isEmpty ? nil : alt))
    }

    private static func splitAtImageLines(_ children: [Markup], lines: SourceLines) -> [ReadBlock]? {
        var blocks: [ReadBlock] = []
        var pending: [Markup] = []
        var line: [Markup] = []
        var foundImage = false
        for (offset, child) in children.enumerated() {
            let isBreak = child is SoftBreak || child is LineBreak
            if isBreak == false {
                line.append(child)
            }
            guard isBreak || offset == children.count - 1 else { continue }
            if line.count == 1, let image = line.first as? Image {
                guard let text = bodyText(pending, lines: lines), let block = imageBlock(image) else { return nil }
                blocks += text + [block]
                pending = []
                foundImage = true
            } else {
                pending += line + (isBreak ? [child] : [])
            }
            line = []
        }
        guard foundImage, let text = bodyText(pending, lines: lines) else { return nil }
        return blocks + text
    }

    private static func bodyText(_ children: [Markup], lines: SourceLines) -> [ReadBlock]? {
        let children = children.last.map { $0 is SoftBreak || $0 is LineBreak } == true ? Array(children.dropLast()) : children
        guard children.isEmpty == false else { return [] }
        guard let text = InlineReader.read(children, source: lines) else { return nil }
        return [ReadBlock(text: text, attributes: BlockAttributes(kind: .body))]
    }

    static func isPlainParagraph(_ paragraph: Paragraph) -> Bool {
        paragraph.children.contains { $0 is Image } == false
    }
}
