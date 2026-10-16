import Foundation
import SlateTestSupport
import Testing
@testable import SlateDomain

@Suite struct RestoreSpaceUseCaseTests {
    @Test func bringsTheFolderAndItsNotesBack() async throws {
        let (ports, spies) = Ports.spies()
        let useCases = UseCases(ports: ports)
        spies.files.seed(VaultPath(rawValue: "Snippets/A.md"), NoteText.make(id: "a", title: "A", body: ""))
        var config = spies.config.config
        config.spaces[4].color = .pink
        spies.config.config = config
        let deletion = try await useCases.deleteSpace.execute(SpaceName(rawValue: "Snippets"))

        let restored = try await useCases.restoreSpace.execute(deletion)

        #expect(restored == [SpaceDeletion.Move(from: VaultPath(rawValue: "Inbox/A.md"), to: VaultPath(rawValue: "Snippets/A.md"))])
        #expect(spies.config.config.spaces.map(\.folder.rawValue) == ["Inbox", "Tasks", "Notes", "Daily", "Snippets", "Archive"])
        #expect(spies.config.config.spaces[4].color == .pink)
        #expect(spies.files.text(at: VaultPath(rawValue: "Snippets/A.md")) != nil)
        #expect(spies.index.indexed[VaultPath(rawValue: "Snippets/A.md")] != nil)
        #expect(spies.index.indexed[VaultPath(rawValue: "Inbox/A.md")] == nil)
    }

    @Test func aNoteMovedAgainSinceStaysWhereItIs() async throws {
        let (ports, spies) = Ports.spies()
        let useCases = UseCases(ports: ports)
        spies.files.seed(VaultPath(rawValue: "Snippets/A.md"), NoteText.make(id: "a", title: "A", body: ""))
        let deletion = try await useCases.deleteSpace.execute(SpaceName(rawValue: "Snippets"))
        _ = try await useCases.move.execute(VaultPath(rawValue: "Inbox/A.md"), to: SpaceName(rawValue: "Notes"))

        let restored = try await useCases.restoreSpace.execute(deletion)

        #expect(restored.isEmpty)
        #expect(spies.files.text(at: VaultPath(rawValue: "Notes/A.md")) != nil)
    }
}
