import Foundation
import SlateDomain
import SlateUI

enum NoteRowMapper {

    static func model(for summary: NoteSummary, type: NoteType?, now: Date) -> NoteRowModel {
        let isPlain = summary.type == NoteType.defaultName
        return NoteRowModel(
            id: summary.id,
            title: summary.title.isEmpty ? StemPolicy.untitled : summary.title,
            preview: summary.preview,
            date: summary.updated.relativeDescription(to: now),
            isPinned: summary.pinned,
            typeIcon: isPlain ? nil : type?.icon ?? "doc",
            typeTitle: isPlain ? nil : type?.title ?? summary.type.capitalized,
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
        if let subfolder = summary.path.subfolder {
            badges.append(TagModel(subfolder, systemImage: "folder"))
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
