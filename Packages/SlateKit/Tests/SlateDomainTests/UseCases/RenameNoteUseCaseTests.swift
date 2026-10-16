import Foundation
import SlateTestSupport
import Testing
@testable import SlateDomain

@Suite struct RenameNoteUseCaseTests {
    private let ports: Ports
    private let spies: PortSpies
    private let path = VaultPath(rawValue: "Inbox/Old.md")

    init() {
        (ports, spies) = Ports.spies()
    }

    private func load(_ path: VaultPath) async throws -> NoteDocument {
        try NoteCodec.decode(try await spies.files.read(path))
    }

    @Test func newTitleMovesTheFileAndWritesTheTitle() async throws {
        spies.files.seed(path, NoteText.make(id: "a", title: "Old", body: "Body"))

        let result = try await UseCases(ports: ports).rename.execute(try await load(path), title: "New name", body: "Body")

        let target = VaultPath(rawValue: "Inbox/New name.md")
        #expect(result.document?.path == target)
        #expect(result.document?.title == "New name")
        #expect(spies.files.paths == [target])
        #expect(spies.index.calls == [.remove(path), .upsert(target)])
        #expect(try await load(target).header.title == "New name")
    }

    @Test func caseOnlyChangeKeepsTheFile() async throws {
        spies.files.seed(path, NoteText.make(id: "a", title: "Old", body: "Body"))

        let result = try await UseCases(ports: ports).rename.execute(try await load(path), title: "OLD", body: "Body")

        #expect(result.document?.path == path)
        #expect(result.document?.title == "OLD")
        #expect(spies.files.calls.contains { if case .move = $0 { true } else { false } } == false)
    }

    @Test func takenNameGetsANumber() async throws {
        spies.files.seed(path, NoteText.make(id: "a", title: "Old", body: "Body"))
        spies.files.seed(VaultPath(rawValue: "Inbox/New.md"), "x")

        let result = try await UseCases(ports: ports).rename.execute(try await load(path), title: "New", body: "Body")

        #expect(result.document?.path == VaultPath(rawValue: "Inbox/New 2.md"))
        #expect(result.document?.title == "New")
    }

    @Test func dailyNoteKeepsItsFileName() async throws {
        let daily = VaultPath(rawValue: "Daily/2026-10-16.md")
        spies.files.seed(daily, NoteText.make(id: "d", title: "2026-10-16", type: "daily", body: "Log"))

        let result = try await UseCases(ports: ports).rename.execute(try await load(daily), title: "Friday", body: "Log")

        #expect(result.document?.path == daily)
        #expect(result.document?.title == "Friday")
    }
}
