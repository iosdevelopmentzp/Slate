import Foundation

package enum SearchFilter: Hashable, Sendable {
    package enum State: String, Hashable, Sendable {
        case todo
        case pinned
        case trashed
        case conflict
    }

    package enum Content: String, Hashable, Sendable {
        case image
        case code
        case link
        case tag
    }

    case tag(String)
    case space(String)
    case type(String)
    case ticket(String)
    case status(String)
    case state(State)
    case has(Content)
    case before(Date)
    case after(Date)
}
