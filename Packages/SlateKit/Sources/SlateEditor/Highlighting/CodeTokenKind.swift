import Foundation

enum CodeTokenKind: Hashable {
    case keyword
    case string
    case comment
    case number
    case type
    case attribute
    case added
    case removed
    case meta
}
