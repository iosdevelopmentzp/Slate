import Foundation

package struct FolderDeletion: Hashable, Sendable {
    package let folder: FolderPath
    package let target: FolderPath
    package let moves: [SpaceDeletion.Move]

    package init(folder: FolderPath, target: FolderPath, moves: [SpaceDeletion.Move]) {
        self.folder = folder
        self.target = target
        self.moves = moves
    }
}
