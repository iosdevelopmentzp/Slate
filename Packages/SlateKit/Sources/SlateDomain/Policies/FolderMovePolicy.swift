import Foundation

package enum FolderMovePolicy {
    package static func target(of folder: FolderPath, into parent: FolderPath?) -> FolderPath? {
        guard let parent else {
            return folder.isSpace ? nil : FolderPath(rawValue: folder.name)
        }
        guard parent != folder, folder.contains(parent) == false, folder.parent != parent else { return nil }
        return parent.appending(folder.name)
    }
}
