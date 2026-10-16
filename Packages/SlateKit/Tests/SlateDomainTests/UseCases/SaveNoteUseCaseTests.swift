import Foundation
import SlateTestSupport
import Testing
@testable import SlateDomain

@Suite struct SaveNoteUseCaseTests {
    private let ports: Ports
    private let spies: PortSpies
    private let path = VaultPath(rawValue: "Inbox/A.md")

    init() {
        (ports, spies) = Ports.spies()
    }

    private func load() async throws -> NoteDocument {
        try NoteCodec.decode(try await spies.files.read(path))
    }

    @Test func unchangedNoteIsNotWritten() async throws {
        spies.files.seed(path, NoteText.make(id: "a", title: "A", body: "Body"))
        let document = try await load()

        let result = try await UseCases(ports: ports).save.execute(document, header: document.header, body: document.body)

        #expect(result == .unchanged(document))
        #expect(spies.files.calls.contains { if case .write = $0 { true } else { false } } == false)
    }

    @Test func changedBodyIsWrittenWithTheLoadedHashAndANewUpdatedDate() async throws {
        let hash = spies.files.seed(path, NoteText.make(id: "a", title: "A", body: "Old"))
        let document = try await load()

        let result = try await UseCases(ports: ports).save.execute(document, header: document.header, body: "New")

        let saved = try #require(result.document)
        #expect(saved.body == "New")
        #expect(saved.header.updated == spies.clock.current)
        #expect(saved.hash != hash)
        #expect(spies.files.calls.last == .write(path, expected: hash))
        #expect(spies.index.calls == [.upsert(path)])
        #expect(spies.files.text(at: path)?.hasSuffix("---\nNew") == true)
    }

    @Test func fileWithoutHeaderGetsAnIDAndTheFileDates() async throws {
        let created = Date(timeIntervalSince1970: 1_000)
        spies.files.seed(path, "Plain text", created: created)
        let document = try await load()

        let saved = try #require(try await UseCases(ports: ports).save.execute(document, header: document.header, body: "Plain text more").document)

        #expect(saved.header.id != nil)
        #expect(saved.header.title == "A")
        #expect(saved.header.created == created)
    }

    @Test func diskChangeIsAConflictAndNothingIsWritten() async throws {
        spies.files.seed(path, NoteText.make(id: "a", title: "A", body: "Old"))
        let document = try await load()
        let other = spies.files.seed(path, NoteText.make(id: "a", title: "A", body: "Theirs"))

        let result = try await UseCases(ports: ports).save.execute(document, header: document.header, body: "Mine")

        #expect(result == .conflict(diskHash: other))
        #expect(spies.files.text(at: path)?.hasSuffix("Theirs") == true)
        #expect(spies.index.calls.isEmpty)
    }

    @Test func opaqueHeaderIsKeptAsIs() async throws {
        let raw = "---\ntitle: A\nauthor:\n  name: Kim\n---\n"
        spies.files.seed(path, raw + "Old")
        let document = try await load()

        _ = try await UseCases(ports: ports).save.execute(document, header: document.header, body: "New")

        #expect(spies.files.text(at: path) == raw + "New")
    }
}
