import AppKit

nonisolated package enum TableAlignment: String, CaseIterable, Sendable {
    case none
    case left
    case center
    case right

    var marker: String {
        switch self {
        case .none: "---"
        case .left: ":---"
        case .center: ":---:"
        case .right: "---:"
        }
    }
}

extension TableAlignment {
    nonisolated var textAlignment: NSTextAlignment {
        switch self {
        case .none, .left: .left
        case .center: .center
        case .right: .right
        }
    }
}
