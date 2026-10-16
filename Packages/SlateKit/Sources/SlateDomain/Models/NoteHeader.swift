import Foundation

package struct NoteHeader: Hashable, Sendable {
    package var id: NoteID?
    package var title: String?
    package var type: String?
    package var created: Date?
    package var updated: Date?
    package var tags: [String]?
    package var pinned: Bool?
    package var ticket: String?
    package var branch: String?
    package var mr: String?
    package var status: String?
    package var language: String?
    package var aliases: [String]?
    package var due: String?
    package var unknownLines: [String]

    package init(
        id: NoteID? = nil,
        title: String? = nil,
        type: String? = nil,
        created: Date? = nil,
        updated: Date? = nil,
        tags: [String]? = nil,
        pinned: Bool? = nil,
        ticket: String? = nil,
        branch: String? = nil,
        mr: String? = nil,
        status: String? = nil,
        language: String? = nil,
        aliases: [String]? = nil,
        due: String? = nil,
        unknownLines: [String] = []
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.created = created
        self.updated = updated
        self.tags = tags
        self.pinned = pinned
        self.ticket = ticket
        self.branch = branch
        self.mr = mr
        self.status = status
        self.language = language
        self.aliases = aliases
        self.due = due
        self.unknownLines = unknownLines
    }

    package static let knownKeys = [
        "id", "title", "type", "created", "updated", "tags", "pinned",
        "ticket", "branch", "mr", "status", "language", "aliases", "due",
    ]
}
