import AppKit

final class ParagraphStyler {
    var configuration: EditorConfiguration {
        didSet { rebuild() }
    }
    var availableWidth: CGFloat = 600
    var image: (String) -> NSImage? = { _ in nil }

    private var scanner = InlineScanner()
    private var proseStyle = NSParagraphStyle()
    private var codeStyle = NSParagraphStyle()
    private var headingFonts: [NSFont] = []

    init(configuration: EditorConfiguration) {
        self.configuration = configuration
        rebuild()
    }

    func style(_ text: String, line: LineState) -> NSAttributedString {
        let result = NSMutableAttributedString(string: text, attributes: baseAttributes)
        let length = result.length
        guard length > 0 else { return result }
        let contentLength = text.hasSuffix("\n") ? length - 1 : length
        let lineText = contentLength == length ? text : String(text.dropLast())
        switch line.kind {
        case .blank:
            break
        case .paragraph:
            applyInline(lineText, offset: 0, to: result)
        case .heading(let level, let markLength):
            let font = headingFonts[min(level, headingFonts.count) - 1]
            result.addAttribute(.font, value: font, range: NSRange(location: 0, length: length))
            result.addAttribute(.paragraphStyle, value: headingStyle(level: level), range: NSRange(location: 0, length: length))
            result.addAttribute(.foregroundColor, value: colors.mark, range: NSRange(location: 0, length: min(markLength, contentLength)))
            applyInline(lineText, offset: 0, to: result)
        case .listItem(let item):
            styleListItem(item, lineText: lineText, contentLength: contentLength, in: result)
        case .quote(let markLength):
            result.addAttribute(.foregroundColor, value: colors.secondaryText, range: NSRange(location: 0, length: contentLength))
            result.addAttribute(.foregroundColor, value: colors.mark, range: NSRange(location: 0, length: min(markLength, contentLength)))
            result.addAttribute(.paragraphStyle, value: quoteStyle, range: NSRange(location: 0, length: length))
            result.addAttribute(.slateDecoration, value: LineDecoration.quote, range: NSRange(location: 0, length: length))
            applyInline(lineText, offset: 0, to: result)
        case .rule:
            result.addAttribute(.foregroundColor, value: colors.mark, range: NSRange(location: 0, length: contentLength))
            result.addAttribute(.slateDecoration, value: LineDecoration.rule, range: NSRange(location: 0, length: length))
        case .tableRow:
            result.addAttribute(.font, value: configuration.codeFont, range: NSRange(location: 0, length: length))
            applyInline(lineText, offset: 0, to: result)
        case .image(let source, _):
            styleImage(source: source, contentLength: contentLength, in: result)
        case .fenceOpen, .fenceClose:
            styleCode(in: result, length: length)
            result.addAttribute(.foregroundColor, value: colors.mark, range: NSRange(location: 0, length: contentLength))
            let isFirst = line.kind != .fenceClose
            result.addAttribute(.slateDecoration, value: LineDecoration.codeBlock(isFirst: isFirst, isLast: isFirst == false), range: NSRange(location: 0, length: length))
        case .code(let language):
            styleCode(in: result, length: length)
            for token in CodeHighlighter.tokens(in: lineText, language: CodeHighlighter.language(named: language)) {
                result.addAttribute(.foregroundColor, value: color(for: token.kind), range: token.range)
            }
            result.addAttribute(.slateDecoration, value: LineDecoration.codeBlock(isFirst: false, isLast: false), range: NSRange(location: 0, length: length))
        }
        return result
    }

    private var colors: EditorColors { configuration.colors }

    private var baseAttributes: [NSAttributedString.Key: Any] {
        [.font: configuration.proseFont, .foregroundColor: colors.text, .paragraphStyle: proseStyle]
    }

    private var quoteStyle: NSParagraphStyle {
        let style = proseStyle.mutableCopy() as! NSMutableParagraphStyle
        style.firstLineHeadIndent = 10
        style.headIndent = 10
        return style
    }

    private func headingStyle(level: Int) -> NSParagraphStyle {
        let style = proseStyle.mutableCopy() as! NSMutableParagraphStyle
        style.paragraphSpacingBefore = level <= 2 ? 6 : 2
        return style
    }

    private func styleListItem(_ item: ListItem, lineText: String, contentLength: Int, in result: NSMutableAttributedString) {
        let prefix = (lineText as NSString).substring(to: min(item.contentStart, contentLength))
        let indent = (prefix as NSString).size(withAttributes: [.font: configuration.proseFont]).width
        let style = proseStyle.mutableCopy() as! NSMutableParagraphStyle
        style.headIndent = indent
        result.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: result.length))
        result.addAttribute(.foregroundColor, value: colors.secondaryText, range: NSRange(location: item.indent, length: min(item.markerLength, contentLength - item.indent)))
        if let checkbox = item.checkbox {
            result.addAttribute(.foregroundColor, value: NSColor.clear, range: checkbox.range)
            result.addAttribute(.slateDecoration, value: LineDecoration.checkbox(isChecked: checkbox.isChecked, location: checkbox.range.location), range: NSRange(location: 0, length: result.length))
            if checkbox.isChecked, item.contentStart < contentLength {
                result.addAttribute(.foregroundColor, value: colors.secondaryText, range: NSRange(location: item.contentStart, length: contentLength - item.contentStart))
            }
        }
        applyInline(lineText, offset: 0, to: result)
    }

    private func styleImage(source: String, contentLength: Int, in result: NSMutableAttributedString) {
        result.addAttribute(.foregroundColor, value: colors.mark, range: NSRange(location: 0, length: contentLength))
        guard let image = image(source), image.size.width > 0, image.size.height > 0 else { return }
        let width = min(image.size.width, max(availableWidth, 40))
        var size = CGSize(width: width, height: image.size.height * width / image.size.width)
        if size.height > configuration.imageMaxHeight {
            size = CGSize(width: size.width * configuration.imageMaxHeight / size.height, height: configuration.imageMaxHeight)
        }
        let style = proseStyle.mutableCopy() as! NSMutableParagraphStyle
        style.paragraphSpacing = size.height + 8
        result.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: result.length))
        result.addAttribute(.slateDecoration, value: LineDecoration.image(image, size: size, source: source), range: NSRange(location: 0, length: result.length))
    }

    private func styleCode(in result: NSMutableAttributedString, length: Int) {
        let range = NSRange(location: 0, length: length)
        result.addAttribute(.font, value: configuration.codeFont, range: range)
        result.addAttribute(.foregroundColor, value: colors.codeText, range: range)
        result.addAttribute(.paragraphStyle, value: codeStyle, range: range)
    }

    private func applyInline(_ line: String, offset: Int, to result: NSMutableAttributedString) {
        for span in scanner.spans(in: line) {
            let range = NSRange(location: span.range.location + offset, length: span.range.length)
            switch span.kind {
            case .mark:
                result.addAttribute(.foregroundColor, value: colors.mark, range: range)
            case .code:
                result.addAttribute(.font, value: inlineCodeFont, range: range)
                result.addAttribute(.backgroundColor, value: colors.codeBackground, range: range)
            case .strong:
                addTrait(.bold, in: range, to: result)
            case .emphasis:
                addTrait(.italic, in: range, to: result)
            case .strike:
                result.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: range)
            case .link(let target), .url(let target):
                result.addAttribute(.foregroundColor, value: colors.link, range: range)
                result.addAttribute(.slateLink, value: EditorLink.url(target), range: range)
            case .wikilink(let target):
                result.addAttribute(.foregroundColor, value: colors.link, range: range)
                result.addAttribute(.slateLink, value: EditorLink.wiki(target), range: range)
            case .tag:
                result.addAttribute(.foregroundColor, value: colors.link, range: range)
            case .pattern(let id, let match):
                result.addAttribute(.foregroundColor, value: colors.link, range: range)
                result.addAttribute(.backgroundColor, value: colors.chipBackground, range: range)
                result.addAttribute(.slateLink, value: EditorLink.pattern(id: id, match: match), range: range)
            }
        }
    }

    private var inlineCodeFont: NSFont {
        NSFont.monospacedSystemFont(ofSize: configuration.proseFont.pointSize - 1, weight: .regular)
    }

    private func addTrait(_ trait: NSFontDescriptor.SymbolicTraits, in range: NSRange, to result: NSMutableAttributedString) {
        result.enumerateAttribute(.font, in: range) { value, subrange, _ in
            guard let font = value as? NSFont else { return }
            let descriptor = font.fontDescriptor.withSymbolicTraits(font.fontDescriptor.symbolicTraits.union(trait))
            let converted = NSFont(descriptor: descriptor, size: font.pointSize) ?? font
            result.addAttribute(.font, value: converted, range: subrange)
        }
    }

    private func color(for kind: CodeTokenKind) -> NSColor {
        switch kind {
        case .keyword: colors.keyword
        case .string: colors.string
        case .comment: colors.comment
        case .number: colors.number
        case .type: colors.type
        case .attribute, .meta: colors.attribute
        case .added: colors.added
        case .removed: colors.removed
        }
    }

    private func rebuild() {
        let prose = NSMutableParagraphStyle()
        prose.lineHeightMultiple = configuration.lineHeightMultiple
        proseStyle = prose
        let code = NSMutableParagraphStyle()
        code.lineHeightMultiple = configuration.codeLineHeightMultiple
        code.firstLineHeadIndent = 8
        code.headIndent = 8
        code.tailIndent = -8
        codeStyle = code
        let size = configuration.proseFont.pointSize
        headingFonts = [1.6, 1.35, 1.15, 1.0, 1.0, 1.0].map { NSFont.systemFont(ofSize: (size * $0).rounded(), weight: .bold) }
        scanner = InlineScanner(patterns: CompiledLinkPattern.compile(configuration.linkPatterns))
    }
}
