import Foundation
import SlateDomain

enum ListSource: Hashable {
    case all
    case space(SpaceName)
    case trash
    case todos

    var space: SpaceName? {
        guard case .space(let name) = self else { return nil }
        return name
    }

    var storedValue: String {
        switch self {
        case .all: "all"
        case .trash: "trash"
        case .todos: "todos"
        case .space(let name): "space:\(name.rawValue)"
        }
    }

    init(storedValue: String?) {
        switch storedValue {
        case "trash":
            self = .trash
        case "todos":
            self = .todos
        case let value? where value.hasPrefix("space:"):
            self = .space(SpaceName(rawValue: String(value.dropFirst("space:".count))))
        default:
            self = .all
        }
    }
}
