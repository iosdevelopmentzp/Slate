import Foundation
import SlateDomain

struct VersionPreview: Hashable {
    let snapshot: Snapshot
    let text: String
    let diff: [DiffLine]
    let added: Int
    let removed: Int
}
