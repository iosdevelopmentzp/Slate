import Foundation
import SlateDomain

struct MoveTargetModel: Identifiable, Hashable {
    let id: FolderPath
    let title: String
    let icon: String
}
