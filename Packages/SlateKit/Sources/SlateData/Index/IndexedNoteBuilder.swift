import Foundation
import Markdown
import SlateDomain

struct IndexedNoteBuilder: IndexedNoteBuilding {
    static let attachmentsFolder = "_attachments/"

    func build(_ document: NoteDocument) -> IndexedNote {
        var walker = BodyFacts()
        walker.visit(Document(parsing: document.body))
        let header = document.header
        let summary = NoteSummary(
            id: document.id,
            path: document.path,
            title: document.title,
            type: document.type,
            status: header.status.flatMap(NoteStatus.init(rawValue:)),
            ticket: header.ticket,
            pinned: header.pinned ?? false,
            created: header.created ?? document.meta.created,
            updated: header.updated ?? document.meta.modified,
            preview: PreviewPolicy.preview(of: document.body),
            openTodos: walker.openTodos,
            attachmentCount: walker.attachments.count,
            headerOpaque: document.isHeaderOpaque
        )
        return IndexedNote(summary: summary, state: IndexedFileState(modified: document.meta.modified, size: document.meta.size, hash: document.hash))
    }

    func headingCount(in body: String) -> Int {
        var walker = BodyFacts()
        walker.visit(Document(parsing: body))
        return walker.headings
    }
}

private struct BodyFacts: MarkupWalker {
    var headings = 0
    var openTodos = 0
    var attachments: Set<String> = []

    mutating func visitHeading(_ heading: Heading) {
        headings += 1
        descendInto(heading)
    }

    mutating func visitListItem(_ listItem: ListItem) {
        if listItem.checkbox == .unchecked {
            openTodos += 1
        }
        descendInto(listItem)
    }

    mutating func visitImage(_ image: Image) {
        record(image.source)
        descendInto(image)
    }

    mutating func visitLink(_ link: Link) {
        record(link.destination)
        descendInto(link)
    }

    private mutating func record(_ destination: String?) {
        guard let destination, destination.contains(IndexedNoteBuilder.attachmentsFolder) else { return }
        attachments.insert(destination)
    }
}
