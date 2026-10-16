import Foundation

package struct NoteSummary: Identifiable, Hashable, Sendable {
    package let id: NoteID
    package var path: VaultPath
    package var title: String
    package var status: NoteStatus?
    package var ticket: String?
    package var pinned: Bool
    package var updated: Date
    package var preview: String
    package var openTodos: Int
    package var attachmentCount: Int

    package var space: SpaceName? {
        path.space
    }

    package init(
        id: NoteID,
        path: VaultPath,
        title: String,
        status: NoteStatus? = nil,
        ticket: String? = nil,
        pinned: Bool = false,
        updated: Date,
        preview: String,
        openTodos: Int = 0,
        attachmentCount: Int = 0
    ) {
        self.id = id
        self.path = path
        self.title = title
        self.status = status
        self.ticket = ticket
        self.pinned = pinned
        self.updated = updated
        self.preview = preview
        self.openTodos = openTodos
        self.attachmentCount = attachmentCount
    }
}
