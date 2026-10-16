import Foundation
import SlateDomain

package final class SpySearchIndex: SearchIndex, @unchecked Sendable {
    package enum Call: Hashable {
        case summaries(space: SpaceName?)
        case upsert(VaultPath)
        case updateState(VaultPath)
        case remove(VaultPath)
        case search(SearchQuery)
        case reset
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var notes: [VaultPath: IndexedNote] = [:]
    private var _summariesError: TestError?

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var summariesError: TestError? {
        get { lock.withLock { _summariesError } }
        set { lock.withLock { _summariesError = newValue } }
    }

    package var indexed: [VaultPath: NoteSummary] {
        lock.withLock { notes.mapValues(\.summary) }
    }

    package func seed(_ summaries: [NoteSummary]) {
        lock.withLock {
            for summary in summaries {
                notes[summary.path] = IndexedNote(summary: summary, state: IndexedFileState(modified: summary.updated, size: 0, hash: ContentHash(rawValue: "seed")))
            }
        }
    }

    package func summaries(space: SpaceName?) async throws -> [NoteSummary] {
        try lock.withLock {
            _calls.append(.summaries(space: space))
            if let _summariesError { throw _summariesError }
            return notes.values.map(\.summary).filter { space == nil || $0.space == space }.sorted { $0.path.rawValue < $1.path.rawValue }
        }
    }

    package func summary(id: NoteID) async throws -> NoteSummary? {
        lock.withLock { notes.values.first { $0.summary.id == id }?.summary }
    }

    package func fileStates() async throws -> [VaultPath: IndexedFileState] {
        lock.withLock { notes.mapValues(\.state) }
    }

    package func upsert(_ note: IndexedNote) async throws {
        lock.withLock {
            _calls.append(.upsert(note.summary.path))
            notes[note.summary.path] = note
        }
    }

    package func updateState(_ state: IndexedFileState, for path: VaultPath) async throws {
        lock.withLock {
            _calls.append(.updateState(path))
            notes[path]?.state = state
        }
    }

    package func remove(path: VaultPath) async throws {
        lock.withLock {
            _calls.append(.remove(path))
            notes[path] = nil
        }
    }

    package func upsert(contentsOf notes: [IndexedNote]) async throws {
        for note in notes {
            try await upsert(note)
        }
    }

    package func search(_ query: SearchQuery, limit: Int) async throws -> [SearchHit] {
        lock.withLock {
            _calls.append(.search(query))
            return SearchMatchPolicy.hits(in: Array(notes.values), query: query, limit: limit)
        }
    }

    package func notes(named stem: String) async throws -> [NoteSummary] {
        lock.withLock { notes.values.map(\.summary).filter { StemPolicy.isSame($0.stem, stem) } }
    }

    package func notes(withTicket ticket: String) async throws -> [NoteSummary] {
        lock.withLock { notes.values.map(\.summary).filter { $0.ticket.map { StemPolicy.isSame($0, ticket) } ?? false } }
    }

    package func notesLinking(to stem: String) async throws -> [NoteSummary] {
        lock.withLock {
            notes.values.filter { note in
                note.links.contains { $0.kind == .wiki && StemPolicy.isSame(WikilinkPolicy.parse($0.target).stem, stem) }
            }.map(\.summary)
        }
    }

    package func tags() async throws -> [TagCount] {
        lock.withLock {
            let all = notes.values.flatMap(\.summary.tags)
            return Dictionary(grouping: all, by: { $0 }).map { TagCount(tag: $0.key, count: $0.value.count) }.sorted { $0.tag < $1.tag }
        }
    }

    package func todos(isDone: Bool) async throws -> [TodoItem] {
        lock.withLock { notes.values.flatMap(\.todos).filter { $0.isDone == isDone }.sorted { ($0.noteID.rawValue, $0.line) < ($1.noteID.rawValue, $1.line) } }
    }

    package func reset() async throws {
        lock.withLock {
            _calls.append(.reset)
            notes.removeAll()
        }
    }
}
