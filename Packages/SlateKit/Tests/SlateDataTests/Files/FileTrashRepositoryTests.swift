import Foundation
import SlateDomain
import SlateTestSupport
import Testing
@testable import SlateData

@Suite struct FileTrashRepositoryTests {
    private let folder: TemporaryDirectory
    private let repository: FileTrashRepository
    private let path = VaultPath(rawValue: "Tasks/Old.md")
    private let date = Date(timeIntervalSince1970: 1_792_131_153)

    init() throws {
        folder = try TemporaryDirectory()
        repository = FileTrashRepository(root: folder.url)
    }

    @Test func trashMovesTheFileAndWritesTheManifest() async throws {
        _ = try folder.write("x", to: path.rawValue)

        let item = try await repository.trash(path, at: date)

        #expect(item == TrashItem(path: path, originalPath: path, trashedAt: date))
        #expect(FileManager.default.fileExists(atPath: folder.path(path.rawValue)) == false)
        #expect(FileManager.default.fileExists(atPath: folder.path(".trash/Tasks/Old.md")))
        let manifest = try String(contentsOf: folder.url.appendingPathComponent(".trash/manifest.json"), encoding: .utf8)
        #expect(manifest.contains(#""originalPath" : "Tasks/Old.md""#))
        #expect(try await repository.items() == [item])
    }

    @Test func sameNameTrashedTwiceGetsANumber() async throws {
        _ = try folder.write("1", to: path.rawValue)
        _ = try await repository.trash(path, at: date)
        _ = try folder.write("2", to: path.rawValue)

        let second = try await repository.trash(path, at: date)

        #expect(second.path == VaultPath(rawValue: "Tasks/Old 2.md"))
        #expect(second.originalPath == path)
    }

    @Test func restorePutsTheFileBackWithAUniqueName() async throws {
        _ = try folder.write("x", to: path.rawValue)
        let item = try await repository.trash(path, at: date)
        _ = try folder.write("new", to: path.rawValue)

        let restored = try await repository.restore(item)

        #expect(restored == VaultPath(rawValue: "Tasks/Old 2.md"))
        #expect(try String(contentsOf: folder.url.appendingPathComponent(restored.rawValue), encoding: .utf8) == "x")
        #expect(try await repository.items().isEmpty)
    }

    @Test func fileWithoutAManifestEntryIsListedForInbox() async throws {
        _ = try folder.write("x", to: ".trash/Loose.md")

        let items = try await repository.items()

        #expect(items.map(\.originalPath) == [VaultPath(rawValue: "Inbox/Loose.md")])
    }
}
