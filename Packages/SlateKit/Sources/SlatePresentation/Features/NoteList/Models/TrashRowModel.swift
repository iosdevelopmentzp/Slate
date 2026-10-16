import Foundation
import SlateDomain

struct TrashRowModel: Identifiable, Hashable {
    let id: VaultPath
    let title: String
    let detail: String

    static let preview = TrashRowModel(id: VaultPath(rawValue: "Inbox/Old meeting notes.md"), title: "Old meeting notes", detail: "From Inbox · 3 days ago")
}
