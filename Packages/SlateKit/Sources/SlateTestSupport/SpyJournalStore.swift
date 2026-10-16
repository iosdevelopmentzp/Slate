import Foundation
import SlateDomain

package final class SpyJournalStore: JournalStore, @unchecked Sendable {
    private let lock = NSLock()
    private var _entries: [NoteID: JournalEntry] = [:]
    private var _saves = 0

    package init() {}

    package var entries: [NoteID: JournalEntry] {
        get { lock.withLock { _entries } }
        set { lock.withLock { _entries = newValue } }
    }

    package var saveCount: Int {
        lock.withLock { _saves }
    }

    package func save(_ entry: JournalEntry) async throws {
        lock.withLock {
            _saves += 1
            _entries[entry.noteID] = entry
        }
    }

    package func entry(for id: NoteID) async throws -> JournalEntry? {
        lock.withLock { _entries[id] }
    }

    package func clear(_ id: NoteID) async throws {
        lock.withLock { _entries[id] = nil }
    }
}
