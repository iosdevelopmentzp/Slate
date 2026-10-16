import Foundation

package enum IndexFactsPolicy {
    package static func note(for document: NoteDocument, attachmentCount: Int? = nil) -> IndexedNote {
        let header = document.header
        let id = document.id
        let lines = MarkdownText.proseLines(of: document.body)
        let todos = lines.compactMap { line -> TodoItem? in
            guard let parsed = TodoLinePolicy.parse(line.text) else { return nil }
            return TodoItem(noteID: id, line: line.index, text: parsed.text, isDone: parsed.isDone)
        }
        let attachments = attachmentCount ?? Set(lines.map(\.text).filter { $0.contains("_attachments/") }).count
        let summary = NoteSummary(
            id: id,
            path: document.path,
            title: document.title,
            type: document.type,
            status: header.status.flatMap(NoteStatus.init(rawValue:)),
            ticket: header.ticket,
            pinned: header.pinned ?? false,
            created: header.created ?? document.meta.created,
            updated: header.updated ?? document.meta.modified,
            preview: PreviewPolicy.preview(of: document.body),
            openTodos: todos.filter { $0.isDone == false }.count,
            attachmentCount: attachments,
            headerOpaque: document.isHeaderOpaque,
            tags: TagPolicy.merged(header: header.tags, lines: lines)
        )
        let wikilinks = WikilinkPolicy.targets(in: lines).map { IndexedLink(kind: .wiki, target: $0) }
        return IndexedNote(
            summary: summary,
            state: IndexedFileState(modified: document.meta.modified, size: document.meta.size, hash: document.hash),
            body: document.body,
            aliases: header.aliases ?? [],
            links: wikilinks,
            todos: todos,
            hasCode: document.body.contains("```"),
            hasImage: document.body.contains("!["),
            hasLink: wikilinks.isEmpty == false || document.body.contains("://")
        )
    }
}
