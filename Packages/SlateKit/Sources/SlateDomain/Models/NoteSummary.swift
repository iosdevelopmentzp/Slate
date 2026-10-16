import Foundation

package struct NoteSummary: Identifiable, Hashable, Sendable {
    package let id: NoteID
    package var path: VaultPath
    package var title: String
    package var type: String
    package var status: NoteStatus?
    package var ticket: String?
    package var pinned: Bool
    package var created: Date
    package var updated: Date
    package var preview: String
    package var openTodos: Int
    package var attachmentCount: Int
    package var headerOpaque: Bool
    package var tags: [String]

    package var space: SpaceName? {
        path.space
    }

    package var stem: String {
        path.stem
    }

    package init(
        id: NoteID,
        path: VaultPath,
        title: String,
        type: String = NoteType.defaultName,
        status: NoteStatus? = nil,
        ticket: String? = nil,
        pinned: Bool = false,
        created: Date? = nil,
        updated: Date,
        preview: String,
        openTodos: Int = 0,
        attachmentCount: Int = 0,
        headerOpaque: Bool = false,
        tags: [String] = []
    ) {
        self.id = id
        self.path = path
        self.title = title
        self.type = type
        self.status = status
        self.ticket = ticket
        self.pinned = pinned
        self.created = created ?? updated
        self.updated = updated
        self.preview = preview
        self.openTodos = openTodos
        self.attachmentCount = attachmentCount
        self.headerOpaque = headerOpaque
        self.tags = tags
    }
}
