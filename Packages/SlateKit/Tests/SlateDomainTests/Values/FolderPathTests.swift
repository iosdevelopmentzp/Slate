import Testing
@testable import SlateDomain

@Suite struct FolderPathTests {
    private let clients = FolderPath(rawValue: "Work/Clients")

    @Test func partsOfAPath() {
        #expect(clients.space == SpaceName(rawValue: "Work"))
        #expect(clients.name == "Clients")
        #expect(clients.depth == 2)
        #expect(clients.parent == FolderPath(rawValue: "Work"))
        #expect(clients.isSpace == false)
        #expect(FolderPath(space: SpaceName(rawValue: "Work")).parent == nil)
        #expect(clients.appending("2026") == FolderPath(rawValue: "Work/Clients/2026"))
    }

    @Test func containsOnlyWhatIsBelow() {
        #expect(clients.contains(VaultPath(rawValue: "Work/Clients/A.md")))
        #expect(clients.contains(VaultPath(rawValue: "Work/Clients/2026/B.md")))
        #expect(clients.contains(VaultPath(rawValue: "Work/Clients Old/C.md")) == false)
        #expect(clients.contains(VaultPath(rawValue: "Work/D.md")) == false)
        #expect(clients.contains(FolderPath(rawValue: "Work/Clients/2026")))
        #expect(clients.contains(clients) == false)
    }

    @Test func movedFollowsARenamedAncestor() {
        let renamed = FolderPath(rawValue: "Work/Customers")

        #expect(clients.moved(from: clients, to: renamed) == renamed)
        #expect(FolderPath(rawValue: "Work/Clients/2026").moved(from: clients, to: renamed) == FolderPath(rawValue: "Work/Customers/2026"))
        #expect(FolderPath(rawValue: "Work/Other").moved(from: clients, to: renamed) == FolderPath(rawValue: "Work/Other"))
    }

    @Test func aNotePathKnowsItsFolder() {
        #expect(VaultPath(folder: clients, stem: "Plan") == VaultPath(rawValue: "Work/Clients/Plan.md"))
        #expect(VaultPath(rawValue: "Work/Clients/Plan.md").folderPath == clients)
        #expect(VaultPath(rawValue: "_attachments/a.png").folderPath == nil)
    }
}
