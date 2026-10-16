import Foundation
import SlateDomain
import SlateTestSupport
import Testing
@testable import SlateData

@Suite struct FileVaultStoreTests {
    private let folder: TemporaryDirectory
    private let ownWrites = OwnWrites()
    private let store: FileVaultStore
    private let path = VaultPath(rawValue: "Inbox/A.md")

    init() throws {
        folder = try TemporaryDirectory()
        store = FileVaultStore(root: folder.url, ownWrites: ownWrites)
    }

    @Test func enumerateListsNotesInSpacesOnly() async throws {
        _ = try folder.write("a", to: "Inbox/A.md")
        _ = try folder.write("b", to: "Notes/Swift/B.md")
        _ = try folder.write("c", to: "Inbox/image.png")
        _ = try folder.write("d", to: "_templates/task.md")
        _ = try folder.write("e", to: ".trash/Inbox/E.md")
        _ = try folder.write("f", to: "Inbox/.hidden.md")
        _ = try folder.write("g", to: "Root.md")

        let paths = Set(try await store.enumerate().map(\.path))

        #expect(paths == [VaultPath(rawValue: "Inbox/A.md"), VaultPath(rawValue: "Notes/Swift/B.md")])
    }

    @Test func readReturnsBytesHashAndMeta() async throws {
        _ = try folder.write("hello", to: path.rawValue)

        let contents = try await store.read(path)

        #expect(String(decoding: contents.data, as: UTF8.self) == "hello")
        #expect(contents.hash == ContentHash.of(Data("hello".utf8)))
        #expect(contents.meta.size == 5)
        #expect(contents.meta.path == path)
    }

    @Test func readOfAMissingFileThrowsNotFound() async throws {
        await #expect(throws: VaultError.notFound(path)) {
            try await store.read(path)
        }
    }

    @Test func writeReplacesAtomicallyAndLeavesNoTemporaryFile() async throws {
        _ = try folder.write("old", to: path.rawValue)
        let loaded = try await store.read(path)

        let result = try await store.write(path, data: Data("new".utf8), expected: loaded.hash)

        #expect(result == .written(.of(Data("new".utf8))))
        #expect(try String(contentsOf: folder.url.appendingPathComponent(path.rawValue), encoding: .utf8) == "new")
        let names = try FileManager.default.contentsOfDirectory(atPath: folder.path("Inbox"))
        #expect(names == ["A.md"])
        #expect(ownWrites.isOwn(path, diskHash: .of(Data("new".utf8))))
    }

    @Test func writeKeepsTheCreationDate() async throws {
        let url = try folder.write("old", to: path.rawValue)
        let created = Date(timeIntervalSince1970: 1_000_000)
        try FileManager.default.setAttributes([.creationDate: created], ofItemAtPath: url.path)

        _ = try await store.write(path, data: Data("new".utf8), expected: nil)

        #expect(try await store.meta(path)?.created == created)
    }

    @Test func writeWithAStaleHashIsAConflictAndKeepsTheDisk() async throws {
        _ = try folder.write("old", to: path.rawValue)
        let loaded = try await store.read(path)
        _ = try folder.write("theirs", to: path.rawValue)

        let result = try await store.write(path, data: Data("mine".utf8), expected: loaded.hash)

        #expect(result == .conflict(diskHash: .of(Data("theirs".utf8))))
        #expect(try String(contentsOf: folder.url.appendingPathComponent(path.rawValue), encoding: .utf8) == "theirs")
    }

    @Test func writeWithAnExpectedHashToADeletedFileIsAConflict() async throws {
        let result = try await store.write(path, data: Data("mine".utf8), expected: ContentHash(rawValue: "x"))

        #expect(result == .conflict(diskHash: nil))
    }

    @Test func createMakesFoldersAndRefusesToOverwrite() async throws {
        let nested = VaultPath(rawValue: "Reading/Book.md")

        _ = try await store.create(nested, data: Data("x".utf8))

        #expect(try await store.meta(nested) != nil)
        await #expect(throws: VaultError.alreadyExists(nested.rawValue)) {
            try await store.create(nested, data: Data("y".utf8))
        }
    }

    @Test func moveRenamesAndRefusesAnExistingTarget() async throws {
        _ = try folder.write("a", to: path.rawValue)
        _ = try folder.write("b", to: "Inbox/B.md")
        let target = VaultPath(rawValue: "Archive/A.md")

        try await store.move(from: path, to: target)

        #expect(try await store.meta(path) == nil)
        #expect(String(decoding: try await store.read(target).data, as: UTF8.self) == "a")
        await #expect(throws: VaultError.alreadyExists("Archive/A.md")) {
            try await store.move(from: VaultPath(rawValue: "Inbox/B.md"), to: target)
        }
    }

    @Test func fileNamesSkipsHiddenFiles() async throws {
        _ = try folder.write("a", to: "Inbox/A.md")
        _ = try folder.write("b", to: "Inbox/.A.md.slate-tmp")

        #expect(try await store.fileNames(inFolder: "Inbox") == ["A.md"])
        #expect(try await store.fileNames(inFolder: "Missing").isEmpty)
    }

    @Test func folderCanBeCreatedAndRenamedEvenByCaseOnly() async throws {
        let reading = SpaceName(rawValue: "Reading")
        try await store.createFolder(reading)
        _ = try folder.write("a", to: "Reading/A.md")

        try await store.moveFolder(from: reading, to: SpaceName(rawValue: "reading"))

        let names = try FileManager.default.contentsOfDirectory(atPath: folder.url.path)
        #expect(names.contains("reading"))
        #expect(names.contains("Reading") == false)
        #expect(try await store.meta(VaultPath(rawValue: "reading/A.md")) != nil)
    }
}
