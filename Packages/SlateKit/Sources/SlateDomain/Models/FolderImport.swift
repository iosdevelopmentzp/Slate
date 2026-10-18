import Foundation

package struct FolderImport: Hashable, Sendable {
    package var notes: Int
    package var files: Int
    package var repository: String?
    package var notesOnly: Bool

    package init(notes: Int = 0, files: Int = 0, repository: String? = nil, notesOnly: Bool = false) {
        self.notes = notes
        self.files = files
        self.repository = repository
        self.notesOnly = notesOnly
    }
}
