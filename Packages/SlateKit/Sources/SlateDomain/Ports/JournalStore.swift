import Foundation

package protocol JournalStore: Sendable {
    func save(_ entry: JournalEntry) async throws
    func entry(for id: NoteID) async throws -> JournalEntry?
    func clear(_ id: NoteID) async throws
}
