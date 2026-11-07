import AppKit

final class RichTextStyler {
    nonisolated static let listIndent: CGFloat = 24
    nonisolated static let markerWidth: CGFloat = 26
    nonisolated static let quoteIndent: CGFloat = 16
    nonisolated static let blockInset: CGFloat = 12
    nonisolated static let calloutIconWidth: CGFloat = 22

    var configuration: EditorConfiguration {
        didSet {
            guard configuration != oldValue else { return }
            fonts.removeAll()
            styles.removeAll()
        }
    }
    var loadImage: (String) -> NSImage? = { _ in nil }
    weak var tableHost: (any TableHost)?

    private var fonts: [FontKey: NSFont] = [:]
    private var styles: [StyleKey: NSParagraphStyle] = [:]
    private var attachments: [String: ImageAttachment] = [:]

    init(configuration: EditorConfiguration) {
        self.configuration = configuration
    }

    func forgetImages() {
        attachments.removeAll()
    }

    func size(for kind: BlockKind) -> CGFloat {
        let base: CGFloat
        switch kind {
        case .title: base = 24
        case .heading: base = 18
        case .monospaced, .raw: base = 13
        default: base = 15
        }
        return (base * configuration.scale).rounded()
    }

    func font(for kind: BlockKind, inline: InlineStyle) -> NSFont {
        let key = FontKey(kind: kind, inline: inline.formattingOnly)
        if let cached = fonts[key] { return cached }
        let size = size(for: kind)
        var font: NSFont
        if kind.keepsLineBreaks {
            font = .monospacedSystemFont(ofSize: size, weight: .regular)
        } else if inline.contains(.code) {
            font = .monospacedSystemFont(ofSize: (size * 0.9).rounded(), weight: inline.contains(.bold) ? .semibold : .regular)
        } else {
            font = .systemFont(ofSize: size, weight: weight(for: kind, bold: inline.contains(.bold)))
        }
        if inline.contains(.italic), kind.keepsLineBreaks == false {
            let descriptor = font.fontDescriptor.withSymbolicTraits(font.fontDescriptor.symbolicTraits.union(.italic))
            font = NSFont(descriptor: descriptor, size: font.pointSize) ?? font
        }
        fonts[key] = font
        return font
    }

    private func weight(for kind: BlockKind, bold: Bool) -> NSFont.Weight {
        switch kind {
        case .title: bold ? .heavy : .bold
        case .heading, .subheading: bold ? .bold : .semibold
        default: bold ? .bold : .regular
        }
    }

    func paragraphStyle(for block: BlockAttributes) -> NSParagraphStyle {
        let key = StyleKey(kind: block.kind, indent: block.continuesList ? block.indent : 0, callout: block.callout == nil ? 0 : (block.isCalloutHeader ? 2 : 1))
        if let cached = styles[key] { return cached }
        let scale = configuration.scale
        let style = NSMutableParagraphStyle()
        switch block.kind {
        case .title:
            style.lineHeightMultiple = 1.05
            style.paragraphSpacingBefore = 4 * scale
            style.paragraphSpacing = 8 * scale
        case .heading:
            style.lineHeightMultiple = 1.1
            style.paragraphSpacingBefore = 12 * scale
            style.paragraphSpacing = 4 * scale
        case .subheading:
            style.lineHeightMultiple = 1.15
            style.paragraphSpacingBefore = 8 * scale
            style.paragraphSpacing = 3 * scale
        case .body:
            style.lineHeightMultiple = 1.25
            style.paragraphSpacing = 5 * scale
        case .quote:
            let indent = Self.quoteIndent + (key.callout == 2 ? Self.calloutIconWidth : 0)
            style.lineHeightMultiple = 1.25
            style.firstLineHeadIndent = indent
            style.headIndent = indent
            style.tailIndent = key.callout == 0 ? 0 : -Self.blockInset
            style.paragraphSpacingBefore = key.callout == 2 ? 6 * scale : 0
            style.paragraphSpacing = (key.callout == 0 ? 4 : 6) * scale
        case .bullet, .numbered, .checklist:
            let indent = Self.markerWidth + CGFloat(key.indent) * Self.listIndent
            style.lineHeightMultiple = 1.2
            style.firstLineHeadIndent = indent
            style.headIndent = indent
            style.paragraphSpacing = 2 * scale
        case .monospaced, .raw:
            style.lineHeightMultiple = 1.2
            style.firstLineHeadIndent = Self.blockInset
            style.headIndent = Self.blockInset
            style.tailIndent = -Self.blockInset
            style.paragraphSpacingBefore = 8 * scale
            style.paragraphSpacing = 12 * scale
        case .image, .divider, .table:
            style.paragraphSpacingBefore = 4 * scale
            style.paragraphSpacing = 6 * scale
            if key.indent > 0 {
                style.firstLineHeadIndent = Self.markerWidth + CGFloat(key.indent - 1) * Self.listIndent
                style.headIndent = style.firstLineHeadIndent
            }
        }
        styles[key] = style
        return style
    }

    func attributes(block: BlockAttributes, inline: InlineStyle, href: String?, isHardBreak: Bool = false, number: Int? = nil) -> [NSAttributedString.Key: Any] {
        var attributes = block.attributes
        let effective = block.kind.keepsLineBreaks ? [] : inline
        if effective.isEmpty == false { attributes[.slateInline] = effective.rawValue }
        if let href, block.kind.keepsLineBreaks == false { attributes[.slateHref] = href }
        if isHardBreak { attributes[.slateHardBreak] = true }
        if let number { attributes[.slateListNumber] = number }
        attributes[.font] = font(for: block.kind, inline: effective)
        attributes[.paragraphStyle] = paragraphStyle(for: block)
        let colors = configuration.colors
        var color = colors.text
        if (block.kind == .quote && block.callout == nil) || (block.kind == .checklist && block.isDone) { color = colors.secondaryText }
        if block.isCalloutHeader, let callout = block.callout {
            color = CalloutKind(marker: callout).color
            attributes[.font] = font(for: block.kind, inline: effective.union(.bold))
        }
        if href != nil, block.kind.keepsLineBreaks == false {
            color = colors.link
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }
        if href == nil, let textColor = effective.textColor { color = textColor.displayColor }
        attributes[.foregroundColor] = color
        if effective.contains(.strikethrough) { attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue }
        if effective.contains(.code) { attributes[.backgroundColor] = colors.codeBackground }
        if let highlight = effective.highlight { attributes[.backgroundColor] = highlight.displayColor }
        return attributes
    }

    func style(_ text: NSMutableAttributedString, paragraph range: NSRange, number: Int?) {
        guard range.length > 0 else { return }
        var block = BlockAttributes(text.attributes(at: range.location, effectiveRange: nil))
        let content = contentRange(of: range, in: text)
        if block.kind.isAttachment, content.length == 0 {
            block = block.with(kind: .body)
        }
        var updates: [(NSRange, [NSAttributedString.Key: Any])] = []
        let tokens = codeTokens(in: text, content: content, block: block)
        let references = references(in: text, content: content, block: block)
        text.enumerateAttributes(in: range) { existing, run, _ in
            let inline = InlineStyle(rawValue: existing[.slateInline] as? Int ?? 0)
            var wanted = attributes(
                block: block,
                inline: inline,
                href: existing[.slateHref] as? String,
                isHardBreak: existing[.slateHardBreak] as? Bool ?? false,
                number: block.kind == .numbered ? number : nil
            )
            if wanted[.slateHref] != nil, existing[.slateBareURL] != nil {
                wanted[.slateBareURL] = true
            }
            if block.kind.isAttachment {
                wanted[.attachment] = attachment(for: block, existing: existing[.attachment] as? NSTextAttachment)
            }
            let plain = wanted[.slateHref] == nil && inline.contains(.code) == false
            for (piece, color, reference) in Self.pieces(of: run, tokens: tokens, references: plain ? references : []) {
                var colored = wanted
                if let color { colored[.foregroundColor] = color }
                if let reference {
                    colored[.slateReference] = reference.raw
                    colored[.foregroundColor] = configuration.colors.link
                    colored[.underlineStyle] = NSUnderlineStyle.single.union(.patternDot).rawValue
                }
                if (existing as NSDictionary).isEqual(to: colored) == false {
                    updates.append((piece, colored))
                }
            }
        }
        for (run, wanted) in updates {
            text.setAttributes(wanted, range: run)
        }
    }

    private func references(in text: NSAttributedString, content: NSRange, block: BlockAttributes) -> [(range: NSRange, reference: TextReference)] {
        guard configuration.references.isEmpty == false, block.kind.keepsLineBreaks == false, block.kind.isAttachment == false, content.length > 0 else { return [] }
        let source = (text.string as NSString).substring(with: content)
        return TextReferenceScanner.references(in: source, kinds: configuration.references).map { found in
            (NSRange(location: found.range.location + content.location, length: found.range.length), found.reference)
        }
    }

    static func pieces(of run: NSRange, tokens: [CodeToken], references: [(range: NSRange, reference: TextReference)]) -> [(NSRange, NSColor?, TextReference?)] {
        var result: [(NSRange, NSColor?, TextReference?)] = []
        for (piece, color) in pieces(of: run, tokens: tokens) {
            var start = piece.location
            for found in references {
                let overlap = NSIntersectionRange(found.range, NSRange(location: start, length: NSMaxRange(piece) - start))
                guard overlap.length > 0 else { continue }
                if overlap.location > start { result.append((NSRange(location: start, length: overlap.location - start), color, nil)) }
                result.append((overlap, color, found.reference))
                start = NSMaxRange(overlap)
            }
            if start < NSMaxRange(piece) { result.append((NSRange(location: start, length: NSMaxRange(piece) - start), color, nil)) }
        }
        return result
    }

    private func codeTokens(in text: NSAttributedString, content: NSRange, block: BlockAttributes) -> [CodeToken] {
        guard block.kind == .monospaced, let name = block.language, content.length > 0 else { return [] }
        let source = (text.string as NSString).substring(with: content)
        return CodeHighlighter.tokens(inBlock: source, language: CodeHighlighter.language(named: name)).map { token in
            CodeToken(range: NSRange(location: token.range.location + content.location, length: token.range.length), kind: token.kind)
        }
    }

    static func pieces(of run: NSRange, tokens: [CodeToken]) -> [(NSRange, NSColor?)] {
        guard tokens.isEmpty == false else { return [(run, nil)] }
        var pieces: [(NSRange, NSColor?)] = []
        var position = run.location
        for token in tokens where NSMaxRange(token.range) > run.location && token.range.location < NSMaxRange(run) {
            let start = max(token.range.location, run.location)
            let end = min(NSMaxRange(token.range), NSMaxRange(run))
            if start > position { pieces.append((NSRange(location: position, length: start - position), nil)) }
            pieces.append((NSRange(location: start, length: end - start), CodePalette.color(for: token.kind)))
            position = end
        }
        if position < NSMaxRange(run) { pieces.append((NSRange(location: position, length: NSMaxRange(run) - position), nil)) }
        return pieces
    }

    private func contentRange(of paragraph: NSRange, in text: NSAttributedString) -> NSRange {
        let string = text.string as NSString
        let end = NSMaxRange(paragraph)
        if end > paragraph.location, string.character(at: end - 1) == 0x0A {
            return NSRange(location: paragraph.location, length: paragraph.length - 1)
        }
        return paragraph
    }

    private func attachment(for block: BlockAttributes, existing: NSTextAttachment?) -> NSTextAttachment {
        if block.kind == .table {
            let table = block.table ?? TableBlock(model: .empty())
            let style = TableStyle(textSize: size(for: .body), colors: configuration.colors)
            if let existing = existing as? TableAttachment {
                existing.update(block: table, style: style)
                return existing
            }
            let created = TableAttachment(block: table, style: style, loadImage: loadImage)
            created.host = tableHost
            return created
        }
        if block.kind == .divider {
            if let divider = existing as? DividerAttachment, divider.color == configuration.colors.divider { return divider }
            return DividerAttachment(color: configuration.colors.divider)
        }
        let path = block.imagePath ?? ""
        let width = ImageSize.width(in: block.imageAlt)
        if let image = existing as? ImageAttachment, image.path == path, image.maxHeight == configuration.imageMaxHeight, image.width == width { return image }
        let key = width.map { "\(path)|\(Int($0))" } ?? path
        if let cached = attachments[key], cached.maxHeight == configuration.imageMaxHeight, cached.width == width { return cached }
        let created = ImageAttachment(path: path, picture: loadImage(path), maxHeight: configuration.imageMaxHeight, borderColor: configuration.colors.imageBorder, width: width)
        attachments[key] = created
        return created
    }
}
