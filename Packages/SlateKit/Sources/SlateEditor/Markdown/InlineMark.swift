import Foundation

enum InlineMark: Equatable {
    case highlight(HighlightColor)
    case textColor(TextColor)
    case flag(InlineStyle)

    static func marks(of style: InlineStyle) -> [InlineMark] {
        var marks: [InlineMark] = []
        if let highlight = style.highlight { marks.append(.highlight(highlight)) }
        if let color = style.textColor { marks.append(.textColor(color)) }
        marks += InlineStyle.flags.filter { style.contains($0) }.map(InlineMark.flag)
        return marks
    }

    var opening: String {
        switch self {
        case .highlight(.yellow): "=="
        case .highlight(let color): InlineHTMLTag.open(color)
        case .textColor(let color): InlineHTMLTag.open(color)
        case .flag(let flag): Self.delimiter(flag)
        }
    }

    var closing: String {
        switch self {
        case .highlight(.yellow): "=="
        case .highlight: InlineHTMLTag.closingHighlight
        case .textColor: InlineHTMLTag.closingTextColor
        case .flag(let flag): Self.delimiter(flag)
        }
    }

    private static func delimiter(_ flag: InlineStyle) -> String {
        switch flag {
        case .bold: "**"
        case .italic: "*"
        default: "~~"
        }
    }
}
