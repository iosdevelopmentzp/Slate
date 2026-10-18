import Foundation

package struct ProjectTask: Hashable, Sendable {
    package let id: NoteID
    package let path: VaultPath
    package let title: String
    package let status: NoteStatus
    package let ticket: String?
    package let branch: String?
    package let updated: Date

    package var folder: FolderPath? {
        path.folderPath
    }

    package init(id: NoteID, path: VaultPath, title: String, status: NoteStatus, ticket: String?, branch: String?, updated: Date) {
        self.id = id
        self.path = path
        self.title = title
        self.status = status
        self.ticket = ticket
        self.branch = branch
        self.updated = updated
    }

    package func matches(branch current: String?) -> Bool {
        guard let current, current.isEmpty == false else { return false }
        if let branch, branch == current { return true }
        guard let ticket, ticket.isEmpty == false else { return false }
        return current.range(of: ticket, options: .caseInsensitive) != nil
    }
}
