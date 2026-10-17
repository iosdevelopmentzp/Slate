import AppKit

nonisolated struct TableStyle: Equatable, Sendable {
    var textSize: CGFloat
    var colors: EditorColors

    init(textSize: CGFloat = 15, colors: EditorColors = .system) {
        self.textSize = textSize
        self.colors = colors
    }

    func font(inline: InlineStyle, header: Bool) -> NSFont {
        var font: NSFont
        if inline.contains(.code) {
            font = .monospacedSystemFont(ofSize: (textSize * 0.9).rounded(), weight: inline.contains(.bold) || header ? .semibold : .regular)
        } else {
            let weight: NSFont.Weight = inline.contains(.bold) ? .bold : (header ? .semibold : .regular)
            font = .systemFont(ofSize: textSize, weight: weight)
        }
        if inline.contains(.italic) {
            let descriptor = font.fontDescriptor.withSymbolicTraits(font.fontDescriptor.symbolicTraits.union(.italic))
            font = NSFont(descriptor: descriptor, size: font.pointSize) ?? font
        }
        return font
    }

    func styled(_ inline: NSAttributedString, header: Bool, alignment: TableAlignment) -> NSAttributedString {
        let result = NSMutableAttributedString(attributedString: inline)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment.textAlignment
        paragraph.lineBreakMode = .byWordWrapping
        let whole = NSRange(location: 0, length: result.length)
        result.addAttribute(.paragraphStyle, value: paragraph, range: whole)
        result.enumerateAttributes(in: whole) { attributes, range, _ in
            let style = InlineStyle(rawValue: attributes[.slateInline] as? Int ?? 0)
            var added: [NSAttributedString.Key: Any] = [.font: font(inline: style, header: header)]
            if attributes[.slateHref] != nil {
                added[.foregroundColor] = colors.link
                added[.underlineStyle] = NSUnderlineStyle.single.rawValue
            } else {
                added[.foregroundColor] = colors.text
            }
            if style.contains(.strikethrough) { added[.strikethroughStyle] = NSUnderlineStyle.single.rawValue }
            if style.contains(.code) { added[.backgroundColor] = colors.codeBackground }
            result.addAttributes(added, range: range)
        }
        return result
    }

    func typingAttributes(header: Bool, alignment: TableAlignment) -> [NSAttributedString.Key: Any] {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment.textAlignment
        return [.font: font(inline: [], header: header), .foregroundColor: colors.text, .paragraphStyle: paragraph]
    }

    var lineHeight: CGFloat {
        let font = font(inline: [], header: false)
        return ceil(font.ascender - font.descender + font.leading)
    }
}
