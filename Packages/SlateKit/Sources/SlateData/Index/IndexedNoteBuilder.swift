import Foundation
import Markdown
import SlateDomain

struct IndexedNoteBuilder: IndexedNoteBuilding {
    static let attachmentsFolder = "_attachments/"

    func build(_ document: NoteDocument) -> IndexedNote {
        var walker = BodyFacts()
        walker.visit(Document(parsing: document.body))
        var note = IndexFactsPolicy.note(for: document, attachmentCount: walker.attachments.count)
        note.links += walker.urls.sorted().map { IndexedLink(kind: .url, target: $0) }
        note.attachments = walker.attachments.sorted()
        note.hasCode = walker.hasCode
        note.hasImage = walker.hasImage
        note.hasLink = note.hasLink || walker.urls.isEmpty == false
        return note
    }

    func headingCount(in body: String) -> Int {
        var walker = BodyFacts()
        walker.visit(Document(parsing: body))
        return walker.headings
    }
}

private struct BodyFacts: MarkupWalker {
    var headings = 0
    var attachments: Set<String> = []
    var urls: Set<String> = []
    var hasCode = false
    var hasImage = false

    mutating func visitHeading(_ heading: Heading) {
        headings += 1
        descendInto(heading)
    }

    mutating func visitCodeBlock(_ codeBlock: CodeBlock) {
        hasCode = true
    }

    mutating func visitImage(_ image: Image) {
        hasImage = true
        record(image.source)
        descendInto(image)
    }

    mutating func visitLink(_ link: Link) {
        record(link.destination)
        if let destination = link.destination, destination.contains("://") {
            urls.insert(destination)
        }
        descendInto(link)
    }

    private mutating func record(_ destination: String?) {
        guard let destination, destination.contains(IndexedNoteBuilder.attachmentsFolder) else { return }
        attachments.insert(destination)
    }
}
