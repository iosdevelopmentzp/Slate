import Foundation
import SlateDomain

struct TrashRowModel: Identifiable, Hashable {
    let id: VaultPath
    let title: String
    let detail: String

    static let preview = TrashRowModel(id: VaultPath(rawValue: "Notes/Old shopping list.md"), title: "Old shopping list", detail: "From Notes · 3 days ago")
}
