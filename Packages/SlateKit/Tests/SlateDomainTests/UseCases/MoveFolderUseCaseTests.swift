import Foundation
import SlateTestSupport
import Testing
@testable import SlateDomain

@Suite struct MoveFolderUseCaseTests {
    private let ports: Ports
    private let spies: PortSpies
    private let clients = FolderPath(rawValue: "Notes/Clients")

    init() {
        (ports, spies) = Ports.spies()
    }

    @Test func aSubFolderMovesIntoAnotherFolderWithItsNotesAndImageLinks() async throws {
        spies.files.seedFolder(clients)
        spies.files.seedFolder(FolderPath(rawValue: "Tasks/2026"))
        spies.files.seed(VaultPath(rawValue: "Notes/Clients/A.md"), NoteText.make(id: "a", title: "A", body: "![](../../_attachments/a.png)\n"))

        let done = try #require(try await UseCases(ports: ports).moveFolder.execute(clients, into: FolderPath(rawValue: "Tasks/2026")))

        let moved = VaultPath(rawValue: "Tasks/2026/Clients/A.md")
        #expect(done.to == FolderPath(rawValue: "Tasks/2026/Clients"))
        #expect(spies.files.paths == [moved])
        #expect(spies.files.text(at: moved)?.contains("![](../../../_attachments/a.png)") == true)
        #expect(Set(spies.index.indexed.keys) == [moved])
    }

    @Test func aTopLevelFolderMovesInsideAndUndoBringsBackItsLook() async throws {
        let snippets = FolderPath(rawValue: "Snippets")
        var config = spies.config.config
        config.spaces[4].color = .green
        spies.config.config = config
        spies.files.seed(VaultPath(rawValue: "Snippets/S.md"), NoteText.make(id: "s", title: "S", body: ""))

        let done = try #require(try await UseCases(ports: ports).moveFolder.execute(snippets, into: FolderPath(rawValue: "Notes")))

        #expect(done.to == FolderPath(rawValue: "Notes/Snippets"))
        #expect(spies.config.config.spaces.map(\.folder.rawValue) == ["Inbox", "Tasks", "Notes", "Daily", "Archive"])
        #expect(spies.files.paths == [VaultPath(rawValue: "Notes/Snippets/S.md")])

        try await UseCases(ports: ports).moveFolder.undo(done)

        #expect(spies.config.config.spaces.map(\.folder.rawValue) == ["Inbox", "Tasks", "Notes", "Daily", "Snippets", "Archive"])
        #expect(spies.config.config.spaces[4].color == .green)
        #expect(spies.files.paths == [VaultPath(rawValue: "Snippets/S.md")])
    }

    @Test func aSubFolderMovedToTheTopLevelBecomesAFolderInTheList() async throws {
        spies.files.seedFolder(clients)

        let done = try #require(try await UseCases(ports: ports).moveFolder.execute(clients, into: nil))

        #expect(done.to == FolderPath(rawValue: "Clients"))
        #expect(spies.config.config.spaces.last?.folder == SpaceName(rawValue: "Clients"))
    }

    @Test func theFolderForQuickNotesStaysAtTheTop() async {
        await #expect(throws: VaultError.defaultFolderMove("Inbox")) {
            try await UseCases(ports: ports).moveFolder.execute(FolderPath(rawValue: "Inbox"), into: FolderPath(rawValue: "Notes"))
        }
    }

    @Test func aProjectStaysAtTheTop() async {
        var config = spies.config.config
        config.spaces[2].project = ProjectInfo(id: "p1")
        spies.config.config = config

        await #expect(throws: VaultError.projectMove("Notes")) {
            try await UseCases(ports: ports).moveFolder.execute(FolderPath(rawValue: "Notes"), into: FolderPath(rawValue: "Tasks"))
        }
    }

    @Test func aTakenNameIsRefusedAndNothingMoves() async {
        spies.files.seedFolder(clients)
        spies.files.seedFolder(FolderPath(rawValue: "Tasks/clients"))

        await #expect(throws: VaultError.alreadyExists("Clients")) {
            try await UseCases(ports: ports).moveFolder.execute(clients, into: FolderPath(rawValue: "Tasks"))
        }
        #expect(spies.files.calls.contains { if case .moveFolder = $0 { true } else { false } } == false)
    }

    @Test func aMoveIntoItsOwnSubFolderDoesNothing() async throws {
        spies.files.seedFolder(clients)

        let done = try await UseCases(ports: ports).moveFolder.execute(FolderPath(rawValue: "Notes"), into: clients)

        #expect(done == nil)
    }
}
