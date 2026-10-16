import Foundation
import SlateDomain

enum FolderEdit: Hashable {
    case new
    case rename(SpaceName)
}
