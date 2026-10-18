import Foundation

package struct FolderImport: Hashable, Sendable {
    package var notes: Int
    package var files: Int
    package var repository: String?

    package init(notes: Int = 0, files: Int = 0, repository: String? = nil) {
        self.notes = notes
        self.files = files
        self.repository = repository
    }
}
