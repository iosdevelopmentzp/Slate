import Foundation
import SlateDomain

enum FolderEdit: Hashable {
    case new
    case newProject
    case newTask(SpaceName)
    case newInside(FolderPath)
    case rename(SpaceName)
    case renameFolder(FolderPath)
}
