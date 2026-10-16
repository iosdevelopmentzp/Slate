import Foundation

nonisolated package enum BlockKind: String, CaseIterable, Sendable {
    case title
    case heading
    case subheading
    case body
    case monospaced
    case quote
    case bullet
    case numbered
    case checklist
    case image
    case divider
    case raw

    package var isList: Bool {
        self == .bullet || self == .numbered || self == .checklist
    }

    package var isHeading: Bool {
        self == .title || self == .heading || self == .subheading
    }

    package var isAttachment: Bool {
        self == .image || self == .divider
    }

    package var keepsLineBreaks: Bool {
        self == .monospaced || self == .raw
    }
}
