import Foundation

struct InlineCell {
    let character: Character
    var style: InlineStyle
    let href: String?
    let isHardBreak: Bool

    var isCode: Bool {
        style.contains(.code)
    }

    static func cells(of text: NSAttributedString) -> [InlineCell] {
        var cells: [InlineCell] = []
        text.enumerateAttributes(in: NSRange(location: 0, length: text.length)) { attributes, range, _ in
            let style = InlineStyle(rawValue: attributes[.slateInline] as? Int ?? 0)
            let href = attributes[.slateHref] as? String
            let isHard = attributes[.slateHardBreak] as? Bool ?? false
            let piece = (text.string as NSString).substring(with: range)
            for character in piece where character != Character(RichText.attachmentString) {
                cells.append(InlineCell(character: character, style: character == RichText.lineBreak ? [] : style, href: character == RichText.lineBreak ? nil : href, isHardBreak: isHard))
            }
        }
        return cells
    }
}
