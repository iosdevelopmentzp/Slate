import Foundation
import SlateDomain
import SlateUI

struct NoteRowModel: Identifiable, Hashable {
    let id: NoteID
    let title: String
    let preview: String
    let date: String
    let isPinned: Bool
    let badges: [TagModel]
    let status: Tint?
    let statusHint: String?

    static let preview = NoteRowModel(
        id: NoteID(rawValue: "preview"),
        title: "Fix the crash on launch",
        preview: "The crash happens when the cache folder is missing. Steps to reproduce, findings and the fix plan.",
        date: "10 min",
        isPinned: true,
        badges: [
            TagModel("ABC-123", tint: .blue, systemImage: "ticket"),
            TagModel("2", tint: .secondary, systemImage: "checklist", hint: "2 open checkboxes"),
        ],
        status: .blue,
        statusHint: "In progress"
    )
}
