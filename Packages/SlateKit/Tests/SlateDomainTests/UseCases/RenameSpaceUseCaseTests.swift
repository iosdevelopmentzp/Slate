import Foundation
import SlateTestSupport
import Testing
@testable import SlateDomain

@Suite struct RenameSpaceUseCaseTests {
    @Test func movesTheFolderUpdatesTheConfigAndReindexes() async throws {
        let (ports, spies) = Ports.spies()
        spies.files.seed(VaultPath(rawValue: "Archive/Old.md"), NoteText.make(id: "o", title: "Old", body: ""))

        let renamed = try await UseCases(ports: ports).renameSpace.execute(SpaceName(rawValue: "Archive"), to: "Done")

        #expect(renamed == SpaceName(rawValue: "Done"))
        #expect(spies.files.calls.contains(.moveFolder(from: FolderPath(rawValue: "Archive"), to: FolderPath(space: renamed))))
        #expect(spies.config.config.spaces.map(\.folder.rawValue) == ["Inbox", "Tasks", "Notes", "Daily", "Snippets", "Done"])
        #expect(spies.config.config.archiveSpace == renamed)
        #expect(Set(spies.index.indexed.keys) == [VaultPath(rawValue: "Done/Old.md")])
    }

    @Test func takenNameIsRejected() async throws {
        let (ports, _) = Ports.spies()

        await #expect(throws: VaultError.alreadyExists("Inbox")) {
            try await UseCases(ports: ports).renameSpace.execute(SpaceName(rawValue: "Archive"), to: "Inbox")
        }
    }
}
