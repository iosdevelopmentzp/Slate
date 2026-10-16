import Foundation
import SlateDomain
import SlateUI

enum NoteRowMapper {

    static func model(for summary: NoteSummary, now: Date) -> NoteRowModel {
        NoteRowModel(
            id: summary.id,
            title: summary.title.isEmpty ? StemPolicy.untitled : summary.title,
            preview: summary.preview,
            date: summary.updated.relativeDescription(to: now),
            isPinned: summary.pinned
        )
    }
}
