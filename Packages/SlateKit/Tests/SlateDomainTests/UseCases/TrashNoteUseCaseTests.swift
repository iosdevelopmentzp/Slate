import Foundation
import SlateTestSupport
import Testing
@testable import SlateDomain

@Suite struct TrashNoteUseCaseTests {
    @Test func trashesTheFileAndRemovesItFromTheIndex() async throws {
        let (ports, spies) = Ports.spies()
        let path = VaultPath(rawValue: "Inbox/A.md")
        spies.files.seed(path, "x")

        let item = try await UseCases(ports: ports).trash.execute(path)

        #expect(item.originalPath == path)
        #expect(item.trashedAt == spies.clock.current)
        #expect(spies.trash.calls == [.trash(path)])
        #expect(spies.index.calls == [.remove(path)])
    }

    @Test func restorePutsTheFileBackAndIndexesIt() async throws {
        let (ports, spies) = Ports.spies()
        let path = VaultPath(rawValue: "Inbox/A.md")
        spies.files.seed(path, NoteText.make(id: "a", title: "A", body: ""))
        let useCases = UseCases(ports: ports)
        let item = try await useCases.trash.execute(path)

        let document = try await useCases.restore.execute(item)

        #expect(document.path == path)
        #expect(spies.index.calls.last == .upsert(path))
    }
}
