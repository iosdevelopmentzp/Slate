import Foundation
import SlateDomain
import SlateUI

enum NoteRowMapper {

    static func model(for summary: NoteSummary, now: Date) -> NoteRowModel {
        NoteRowModel(
            id: summary.id,
            title: summary.title.isEmpty ? "Untitled" : summary.title,
            preview: summary.preview,
            date: summary.updated.relativeDescription(to: now),
            isPinned: summary.pinned,
            badges: badges(for: summary),
            status: summary.status.map(NoteStatusText.tint),
            statusHint: summary.status.map(NoteStatusText.title)
        )
    }

    private static func badges(for summary: NoteSummary) -> [TagModel] {
        var badges: [TagModel] = []
        if let ticket = summary.ticket {
            badges.append(TagModel(ticket, tint: .blue, systemImage: "ticket"))
        }
        if summary.attachmentCount > 0 {
            badges.append(TagModel("\(summary.attachmentCount)", systemImage: "paperclip", hint: CountText.count(summary.attachmentCount, "image or file", "images or files")))
        }
        if summary.openTodos > 0 {
            badges.append(TagModel("\(summary.openTodos)", systemImage: "checklist", hint: CountText.count(summary.openTodos, "open checkbox", "open checkboxes")))
        }
        return badges
    }
}
