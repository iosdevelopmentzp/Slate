import AppKit

final class RichTextStyler {
    nonisolated static let listIndent: CGFloat = 24
    nonisolated static let markerWidth: CGFloat = 26
    nonisolated static let quoteIndent: CGFloat = 16
    nonisolated static let blockInset: CGFloat = 12

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
        let key = FontKey(kind: kind, inline: inline)
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
        let key = StyleKey(kind: block.kind, indent: block.kind.isList ? block.indent : 0)
        if let cached = styles[key] { return cached }
        let scale = configuration.scale
        let style = NSMutableParagraphStyle()
        switch block.kind {
        case .title:
            style.lineHeightMultiple = 1.1
            style.paragraphSpacingBefore = 6 * scale
            style.paragraphSpacing = 10 * scale
        case .heading:
            style.lineHeightMultiple = 1.15
            style.paragraphSpacingBefore = 14 * scale
            style.paragraphSpacing = 6 * scale
        case .subheading:
            style.lineHeightMultiple = 1.2
            style.paragraphSpacingBefore = 10 * scale
            style.paragraphSpacing = 4 * scale
        case .body:
            style.lineHeightMultiple = 1.4
            style.paragraphSpacing = 8 * scale
        case .quote:
            style.lineHeightMultiple = 1.4
            style.firstLineHeadIndent = Self.quoteIndent
            style.headIndent = Self.quoteIndent
            style.paragraphSpacing = 6 * scale
        case .bullet, .numbered, .checklist:
            let indent = Self.markerWidth + CGFloat(key.indent) * Self.listIndent
            style.lineHeightMultiple = 1.35
            style.firstLineHeadIndent = indent
            style.headIndent = indent
            style.paragraphSpacing = 4 * scale
        case .monospaced, .raw:
            style.lineHeightMultiple = 1.25
            style.firstLineHeadIndent = Self.blockInset
            style.headIndent = Self.blockInset
            style.tailIndent = -Self.blockInset
            style.paragraphSpacingBefore = 8 * scale
            style.paragraphSpacing = 14 * scale
        case .image, .divider, .table:
            style.paragraphSpacingBefore = 4 * scale
            style.paragraphSpacing = 8 * scale
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
        if block.kind == .quote || (block.kind == .checklist && block.isDone) { color = colors.secondaryText }
        if href != nil, block.kind.keepsLineBreaks == false {
            color = colors.link
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }
        attributes[.foregroundColor] = color
        if effective.contains(.strikethrough) { attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue }
        if effective.contains(.code) { attributes[.backgroundColor] = colors.codeBackground }
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
        text.enumerateAttributes(in: range) { existing, run, _ in
            let inline = InlineStyle(rawValue: existing[.slateInline] as? Int ?? 0)
            var wanted = attributes(
                block: block,
                inline: inline,
                href: existing[.slateHref] as? String,
                isHardBreak: existing[.slateHardBreak] as? Bool ?? false,
                number: block.kind == .numbered ? number : nil
            )
            if block.kind.isAttachment {
                wanted[.attachment] = attachment(for: block, existing: existing[.attachment] as? NSTextAttachment)
            }
            if (existing as NSDictionary).isEqual(to: wanted) == false {
                updates.append((run, wanted))
            }
        }
        for (run, wanted) in updates {
            text.setAttributes(wanted, range: run)
        }
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
            let created = TableAttachment(block: table, style: style)
            created.host = tableHost
            return created
        }
        if block.kind == .divider {
            if let divider = existing as? DividerAttachment, divider.color == configuration.colors.divider { return divider }
            return DividerAttachment(color: configuration.colors.divider)
        }
        let path = block.imagePath ?? ""
        if let image = existing as? ImageAttachment, image.path == path, image.maxHeight == configuration.imageMaxHeight { return image }
        if let cached = attachments[path], cached.maxHeight == configuration.imageMaxHeight { return cached }
        let created = ImageAttachment(path: path, picture: loadImage(path), maxHeight: configuration.imageMaxHeight, borderColor: configuration.colors.imageBorder)
        attachments[path] = created
        return created
    }
}
