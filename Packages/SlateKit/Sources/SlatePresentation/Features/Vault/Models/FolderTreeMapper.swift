import Foundation
import SlateDomain

enum FolderTreeMapper {

    static func children(of parent: FolderPath, in folders: [FolderPath]) -> [FolderPath] {
        FolderTree(folders).children(of: parent)
    }

    static func nodes(below space: SpaceName, folders: [FolderPath], expanded: Set<FolderPath>) -> [FolderNode] {
        FolderTree(folders).nodes(below: space, expanded: expanded)
    }

    static func moveTargets(spaces: [SpaceName], folders: [FolderPath]) -> [FolderNode] {
        FolderTree(folders).moveTargets(spaces: spaces)
    }
}
