import Foundation

struct InlineColorState {
    var highlight: HighlightColor?
    var textColor: TextColor?

    var isClosed: Bool {
        highlight == nil && textColor == nil
    }

    func applied(to style: InlineStyle) -> InlineStyle {
        var result = style
        if let highlight { result.highlight = highlight }
        if let textColor { result.textColor = textColor }
        return result
    }

    mutating func take(_ tag: InlineHTMLTag) -> Bool {
        switch tag {
        case .openHighlight(let color):
            guard highlight == nil else { return false }
            highlight = color
        case .closeHighlight:
            guard highlight != nil else { return false }
            highlight = nil
        case .openTextColor(let color):
            guard textColor == nil else { return false }
            textColor = color
        case .closeTextColor:
            guard textColor != nil else { return false }
            textColor = nil
        }
        return true
    }
}
