import Foundation
import SlateDomain

struct FolderNode: Identifiable, Hashable {
    let id: FolderPath
    let level: Int
    let hasChildren: Bool
    let isExpanded: Bool
}
