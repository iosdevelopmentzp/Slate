import Foundation
import SlateDomain

struct FileJournalStore: JournalStore {
    let folder: URL

    func save(_ entry: JournalEntry) async throws {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(entry).write(to: url(for: entry.noteID), options: .atomic)
    }

    func entry(for id: NoteID) async throws -> JournalEntry? {
        let url = url(for: id)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(JournalEntry.self, from: Data(contentsOf: url))
    }

    func clear(_ id: NoteID) async throws {
        let url = url(for: id)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.removeItem(at: url)
    }

    private func url(for id: NoteID) -> URL {
        folder.appendingPathComponent(ContentHash.of(Data(id.rawValue.utf8)).rawValue.prefix(24) + ".json")
    }
}
