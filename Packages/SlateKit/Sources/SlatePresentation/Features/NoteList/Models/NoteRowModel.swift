import Foundation
import SlateDomain

struct NoteRowModel: Identifiable, Hashable {
    let id: NoteID
    let title: String
    let preview: String
    let date: String
    let isPinned: Bool

    static let preview = NoteRowModel(
        id: NoteID(rawValue: "preview"),
        title: "Plan for the week",
        preview: "Finish the draft, call the bank, and book the train for Friday.",
        date: "10 min. ago",
        isPinned: true
    )
}
