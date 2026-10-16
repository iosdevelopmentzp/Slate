import Foundation

enum LineKind: Equatable {
    case blank
    case paragraph
    case heading(level: Int, markLength: Int)
    case listItem(ListItem)
    case quote(markLength: Int)
    case rule
    case tableRow
    case image(source: String, sourceRange: NSRange)
    case fenceOpen(language: String)
    case fenceClose
    case code(language: String)

    var isCode: Bool {
        switch self {
        case .fenceOpen, .fenceClose, .code: true
        default: false
        }
    }
}
