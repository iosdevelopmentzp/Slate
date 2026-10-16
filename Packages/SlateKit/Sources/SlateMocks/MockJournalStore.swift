import Foundation
import SlateDomain

struct MockJournalStore: JournalStore {
    func save(_ entry: JournalEntry) async throws {}

    func entry(for id: NoteID) async throws -> JournalEntry? {
        nil
    }

    func clear(_ id: NoteID) async throws {}
}
