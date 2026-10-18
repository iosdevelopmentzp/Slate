import Foundation
import SlateDomain

struct FolderTree: Hashable {
    private let childrenByParent: [FolderPath: [FolderPath]]

    init(_ folders: [FolderPath]) {
        var grouped: [FolderPath: [FolderPath]] = [:]
        for folder in folders {
            guard let parent = folder.parent else { continue }
            grouped[parent, default: []].append(folder)
        }
        childrenByParent = grouped.mapValues { list in
            list.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }
    }

    func children(of parent: FolderPath) -> [FolderPath] {
        childrenByParent[parent] ?? []
    }

    func hasChildren(_ folder: FolderPath) -> Bool {
        childrenByParent[folder]?.isEmpty == false
    }

    func nodes(below space: SpaceName, expanded: Set<FolderPath>) -> [FolderNode] {
        var result: [FolderNode] = []
        append(children(of: FolderPath(space: space)), level: 1, expanded: expanded, showAll: false, into: &result)
        return result
    }

    func moveTargets(spaces: [SpaceName]) -> [FolderNode] {
        var result: [FolderNode] = []
        for space in spaces {
            let root = FolderPath(space: space)
            result.append(FolderNode(id: root, level: 0, hasChildren: hasChildren(root), isExpanded: true))
            append(children(of: root), level: 1, expanded: [], showAll: true, into: &result)
        }
        return result
    }

    private func append(_ list: [FolderPath], level: Int, expanded: Set<FolderPath>, showAll: Bool, into result: inout [FolderNode]) {
        for folder in list {
            let isExpanded = showAll || expanded.contains(folder)
            result.append(FolderNode(id: folder, level: level, hasChildren: hasChildren(folder), isExpanded: isExpanded))
            if isExpanded {
                append(children(of: folder), level: level + 1, expanded: expanded, showAll: showAll, into: &result)
            }
        }
    }
}
