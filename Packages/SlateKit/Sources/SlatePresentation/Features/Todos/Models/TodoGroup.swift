import Foundation
import SlateDomain

struct TodoGroup: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String?
    let noteID: NoteID?
    let items: [TodoItem]
}
