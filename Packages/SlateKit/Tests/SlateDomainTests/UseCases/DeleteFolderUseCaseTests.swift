import Foundation
import SlateTestSupport
import Testing
@testable import SlateDomain

@Suite struct DeleteFolderUseCaseTests {
    private let ports: Ports
    private let spies: PortSpies
    private let work = FolderPath(rawValue: "Work")
    private let clients = FolderPath(rawValue: "Work/Clients")

    init() {
        (ports, spies) = Ports.spies()
    }

    @Test func deleteMovesEveryNoteBelowIntoTheParentAndUndoBringsThemBack() async throws {
        spies.files.seedFolder(clients)
        spies.files.seedFolder(FolderPath(rawValue: "Work/Clients/2026"))
        let top = VaultPath(rawValue: "Work/Clients/A.md")
        let deep = VaultPath(rawValue: "Work/Clients/2026/B.md")
        spies.files.seed(top, NoteText.make(id: "a", title: "A", body: "![](../../_attachments/a.png)\n"))
        spies.files.seed(deep, NoteText.make(id: "b", title: "B", body: ""))

        let deletion = try await UseCases(ports: ports).deleteFolder.execute(clients)

        #expect(deletion.target == work)
        #expect(deletion.moves.map(\.to) == [VaultPath(rawValue: "Work/B.md"), VaultPath(rawValue: "Work/A.md")])
        #expect(spies.files.calls.contains(.removeFolder(clients)))
        #expect(spies.files.text(at: VaultPath(rawValue: "Work/A.md"))?.contains("![](../_attachments/a.png)") == true)

        let restored = try await UseCases(ports: ports).restoreFolder.execute(deletion)

        #expect(Set(restored.map(\.to)) == [top, deep])
        #expect(spies.files.paths == [top, deep])
        #expect(spies.files.text(at: top)?.contains("![](../../_attachments/a.png)") == true)
        #expect(spies.files.folderNames.contains(FolderPath(rawValue: "Work/Clients/2026")))
    }
}
