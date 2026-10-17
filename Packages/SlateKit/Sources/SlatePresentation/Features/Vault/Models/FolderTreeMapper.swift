import Foundation
import SlateDomain

enum FolderTreeMapper {

    static func children(of parent: FolderPath, in folders: [FolderPath]) -> [FolderPath] {
        folders
            .filter { $0.parent == parent }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    static func nodes(below space: SpaceName, folders: [FolderPath], expanded: Set<FolderPath>) -> [FolderNode] {
        var result: [FolderNode] = []
        append(children(of: FolderPath(space: space), in: folders), level: 1, folders: folders, expanded: expanded, showAll: false, into: &result)
        return result
    }

    static func moveTargets(spaces: [SpaceName], folders: [FolderPath]) -> [FolderNode] {
        var result: [FolderNode] = []
        for space in spaces {
            let root = FolderPath(space: space)
            let below = children(of: root, in: folders)
            result.append(FolderNode(id: root, level: 0, hasChildren: below.isEmpty == false, isExpanded: true))
            append(below, level: 1, folders: folders, expanded: [], showAll: true, into: &result)
        }
        return result
    }

    private static func append(_ list: [FolderPath], level: Int, folders: [FolderPath], expanded: Set<FolderPath>, showAll: Bool, into result: inout [FolderNode]) {
        for folder in list {
            let below = children(of: folder, in: folders)
            let isExpanded = showAll || expanded.contains(folder)
            result.append(FolderNode(id: folder, level: level, hasChildren: below.isEmpty == false, isExpanded: isExpanded))
            if isExpanded {
                append(below, level: level + 1, folders: folders, expanded: expanded, showAll: showAll, into: &result)
            }
        }
    }
}
