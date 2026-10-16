import Foundation

struct InlineSpan: Equatable {
    enum Kind: Equatable {
        case mark
        case code
        case strong
        case emphasis
        case strike
        case link(String)
        case wikilink(String)
        case url(String)
        case tag(String)
        case pattern(id: String, match: String)
    }

    let range: NSRange
    let kind: Kind
}
