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
    case table
    case raw

    package var isList: Bool {
        self == .bullet || self == .numbered || self == .checklist
    }

    package var isHeading: Bool {
        self == .title || self == .heading || self == .subheading
    }

    package var headingLevel: Int? {
        switch self {
        case .title: 0
        case .heading: 1
        case .subheading: 2
        default: nil
        }
    }

    package var isAttachment: Bool {
        self == .image || self == .divider || self == .table
    }

    package var keepsLineBreaks: Bool {
        self == .monospaced || self == .raw
    }
}
