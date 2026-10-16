import Foundation
import SlateDomain

package struct SpyIndexedNoteBuilder: IndexedNoteBuilding {
    package init() {}

    package func build(_ document: NoteDocument) -> IndexedNote {
        let summary = NoteSummary(
            id: document.id,
            path: document.path,
            title: document.title,
            type: document.type,
            status: document.header.status.flatMap(NoteStatus.init(rawValue:)),
            ticket: document.header.ticket,
            pinned: document.header.pinned ?? false,
            created: document.header.created ?? document.meta.created,
            updated: document.header.updated ?? document.meta.modified,
            preview: PreviewPolicy.preview(of: document.body),
            headerOpaque: document.isHeaderOpaque
        )
        return IndexedNote(summary: summary, state: IndexedFileState(modified: document.meta.modified, size: document.meta.size, hash: document.hash))
    }
}
