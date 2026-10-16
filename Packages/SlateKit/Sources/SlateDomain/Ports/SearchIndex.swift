import Foundation

package protocol SearchIndex: Sendable {
    func summaries(space: SpaceName?) async throws -> [NoteSummary]
    func summary(id: NoteID) async throws -> NoteSummary?
    func fileStates() async throws -> [VaultPath: IndexedFileState]
    func upsert(_ note: IndexedNote) async throws
    func updateState(_ state: IndexedFileState, for path: VaultPath) async throws
    func remove(path: VaultPath) async throws
}
