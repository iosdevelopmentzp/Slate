import Foundation
import SlateDomain

enum FolderEdit: Hashable {
    case new
    case newProject
    case newInside(FolderPath)
    case rename(SpaceName)
    case renameFolder(FolderPath)
}
