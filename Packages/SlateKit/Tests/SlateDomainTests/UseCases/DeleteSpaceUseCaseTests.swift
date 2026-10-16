import Foundation
import SlateTestSupport
import Testing
@testable import SlateDomain

@Suite struct DeleteSpaceUseCaseTests {
    @Test func movesTheNotesToTheQuickNoteFolderAndRemovesTheFolder() async throws {
        let (ports, spies) = Ports.spies()
        spies.files.seed(VaultPath(rawValue: "Snippets/A.md"), NoteText.make(id: "a", title: "A", body: ""))
        spies.files.seed(VaultPath(rawValue: "Snippets/Deep/B.md"), NoteText.make(id: "b", title: "B", body: ""))
        spies.files.seed(VaultPath(rawValue: "Inbox/A.md"), NoteText.make(id: "c", title: "A", body: ""))

        let deletion = try await UseCases(ports: ports).deleteSpace.execute(SpaceName(rawValue: "Snippets"))

        #expect(deletion.position == 4)
        #expect(deletion.target == SpaceName(rawValue: "Inbox"))
        #expect(deletion.moves == [
            SpaceDeletion.Move(from: VaultPath(rawValue: "Snippets/A.md"), to: VaultPath(rawValue: "Inbox/A 2.md")),
            SpaceDeletion.Move(from: VaultPath(rawValue: "Snippets/Deep/B.md"), to: VaultPath(rawValue: "Inbox/B.md")),
        ])
        #expect(spies.files.calls.contains(.removeFolder(SpaceName(rawValue: "Snippets"))))
        #expect(spies.config.config.spaces.map(\.folder.rawValue) == ["Inbox", "Tasks", "Notes", "Daily", "Archive"])
        #expect(spies.index.indexed[VaultPath(rawValue: "Inbox/B.md")] != nil)
    }

    @Test func theQuickNoteFolderCannotBeDeleted() async throws {
        let (ports, spies) = Ports.spies()

        await #expect(throws: VaultError.defaultFolder("Inbox")) {
            try await UseCases(ports: ports).deleteSpace.execute(SpaceName(rawValue: "Inbox"))
        }
        #expect(spies.files.calls.isEmpty)
    }

    @Test func deletingTheArchiveFolderPointsTheArchiveAtTheQuickNoteFolder() async throws {
        let (ports, spies) = Ports.spies()

        _ = try await UseCases(ports: ports).deleteSpace.execute(SpaceName(rawValue: "Archive"))

        #expect(spies.config.config.archiveSpace == SpaceName(rawValue: "Inbox"))
    }
}
