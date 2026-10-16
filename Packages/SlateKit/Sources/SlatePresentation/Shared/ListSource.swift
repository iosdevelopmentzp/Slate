import Foundation
import SlateDomain

enum ListSource: Hashable {
    case all
    case space(SpaceName)
    case trash

    var space: SpaceName? {
        guard case .space(let name) = self else { return nil }
        return name
    }

    var storedValue: String {
        switch self {
        case .all: "all"
        case .trash: "trash"
        case .space(let name): "space:\(name.rawValue)"
        }
    }

    static func cycle(from current: ListSource, spaces: [SpaceName], by offset: Int) -> ListSource {
        let list: [ListSource] = [.all] + spaces.map { .space($0) } + [.trash]
        let index = list.firstIndex(of: current) ?? 0
        return list[(index + offset % list.count + list.count) % list.count]
    }

    init(storedValue: String?) {
        switch storedValue {
        case "trash":
            self = .trash
        case let value? where value.hasPrefix("space:"):
            self = .space(SpaceName(rawValue: String(value.dropFirst("space:".count))))
        default:
            self = .all
        }
    }
}
