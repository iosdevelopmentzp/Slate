import Foundation
import SlateDomain
import SlateTestSupport
import Testing
@testable import SlateData

@Suite struct FileAttachmentStoreTests {
    private let folder: TemporaryDirectory
    private let store: FileAttachmentStore

    init() throws {
        folder = try TemporaryDirectory()
        store = FileAttachmentStore(root: folder.url)
    }

    @Test func writeCreatesTheFolderAndTheFile() async throws {
        try await store.write(Data([1, 2]), named: "a.png")

        #expect(try await store.fileNames() == ["a.png"])
        #expect(await store.size(of: "a.png") == 2)
        #expect(FileManager.default.fileExists(atPath: folder.path("_attachments/a.png")))
    }

    @Test func writeNeverReplacesAFile() async throws {
        try await store.write(Data([1]), named: "a.png")

        await #expect(throws: VaultError.alreadyExists("a.png")) {
            try await store.write(Data([2]), named: "a.png")
        }
    }

    @Test func copyTakesTheBytesOfTheSource() async throws {
        let source = try folder.write("hello", to: "outside/file.txt")

        try await store.copy(source, named: "file.txt")

        #expect(try String(contentsOf: store.url(for: "file.txt"), encoding: .utf8) == "hello")
        #expect(await store.externalSize(source) == 5)
    }

    @Test func namesWithASlashAreRejected() async throws {
        await #expect(throws: VaultError.invalidName("../x")) {
            try await store.write(Data(), named: "../x")
        }
    }

    @Test func missingFileHasNoSize() async {
        #expect(await store.size(of: "none.png") == nil)
    }
}
