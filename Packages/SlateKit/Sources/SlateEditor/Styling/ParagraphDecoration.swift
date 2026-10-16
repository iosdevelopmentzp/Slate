import AppKit

nonisolated enum ParagraphDecoration: Equatable {
    case none
    case bullet(level: Int)
    case number(Int)
    case checkbox(done: Bool)
    case quote
    case block(raw: Bool)

    static func of(_ attributes: [NSAttributedString.Key: Any]) -> ParagraphDecoration {
        let block = BlockAttributes(attributes)
        switch block.kind {
        case .bullet: return .bullet(level: block.indent)
        case .numbered: return .number(attributes[.slateListNumber] as? Int ?? 1)
        case .checklist: return .checkbox(done: block.isDone)
        case .quote: return .quote
        case .monospaced: return .block(raw: false)
        case .raw: return .block(raw: true)
        default: return .none
        }
    }
}
