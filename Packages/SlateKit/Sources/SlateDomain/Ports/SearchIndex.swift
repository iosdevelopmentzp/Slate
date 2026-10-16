import Foundation

package protocol SearchIndex: Sendable {
    func summaries(space: SpaceName?) async throws -> [NoteSummary]
    func summary(id: NoteID) async throws -> NoteSummary?
    func fileStates() async throws -> [VaultPath: IndexedFileState]
    func upsert(_ note: IndexedNote) async throws
    func upsert(contentsOf notes: [IndexedNote]) async throws
    func updateState(_ state: IndexedFileState, for path: VaultPath) async throws
    func remove(path: VaultPath) async throws
    func search(_ query: SearchQuery, limit: Int) async throws -> [SearchHit]
    func notes(named stem: String) async throws -> [NoteSummary]
    func notes(withTicket ticket: String) async throws -> [NoteSummary]
    func notesLinking(to stem: String) async throws -> [NoteSummary]
    func tags() async throws -> [TagCount]
    func todos(isDone: Bool) async throws -> [TodoItem]
    func reset() async throws
}
