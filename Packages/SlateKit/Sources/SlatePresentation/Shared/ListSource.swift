import Foundation
import SlateDomain

enum ListSource: Hashable {
    case all
    case space(SpaceName)
    case folder(FolderPath)
    case trash

    var space: SpaceName? {
        switch self {
        case .space(let name): name
        case .folder(let folder): folder.space
        case .all, .trash: nil
        }
    }

    var folder: FolderPath? {
        switch self {
        case .space(let name): FolderPath(space: name)
        case .folder(let folder): folder
        case .all, .trash: nil
        }
    }

    func shows(_ path: VaultPath) -> Bool {
        switch self {
        case .all: true
        case .space(let name): path.folder == name.rawValue
        case .folder(let folder): path.folder == folder.rawValue
        case .trash: false
        }
    }

    static func showing(_ folder: FolderPath) -> ListSource {
        folder.isSpace ? .space(folder.space) : .folder(folder)
    }

    var storedValue: String {
        switch self {
        case .all: "all"
        case .trash: "trash"
        case .space(let name): "space:\(name.rawValue)"
        case .folder(let folder): "folder:\(folder.rawValue)"
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
        case let value? where value.hasPrefix("folder:"):
            self = .folder(FolderPath(rawValue: String(value.dropFirst("folder:".count))))
        default:
            self = .all
        }
    }
}
