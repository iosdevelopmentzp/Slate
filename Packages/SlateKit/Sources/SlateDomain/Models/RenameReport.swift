import Foundation

package struct RenameReport: Hashable, Sendable {
    package var result: SaveResult
    package var rewritten: [VaultPath]
    package var failed: [VaultPath]

    package init(result: SaveResult, rewritten: [VaultPath] = [], failed: [VaultPath] = []) {
        self.result = result
        self.rewritten = rewritten
        self.failed = failed
    }

    package var document: NoteDocument? {
        result.document
    }
}
