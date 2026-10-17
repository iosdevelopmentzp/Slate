import Foundation
import SlateDomain

enum FolderEdit: Hashable {
    case new
    case newInside(FolderPath)
    case rename(SpaceName)
    case renameFolder(FolderPath)
}
