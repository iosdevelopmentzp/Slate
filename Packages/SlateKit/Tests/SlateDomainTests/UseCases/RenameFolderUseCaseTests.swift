import Foundation
import SlateTestSupport
import Testing
@testable import SlateDomain

@Suite struct RenameFolderUseCaseTests {
    private let ports: Ports
    private let spies: PortSpies
    private let work = FolderPath(rawValue: "Work")
    private let clients = FolderPath(rawValue: "Work/Clients")

    init() {
        (ports, spies) = Ports.spies()
    }

    @Test func renameMovesTheFolderAndReindexes() async throws {
        spies.files.seedFolder(clients)
        spies.files.seed(VaultPath(rawValue: "Work/Clients/A.md"), NoteText.make(id: "a", title: "A", body: ""))

        let renamed = try await UseCases(ports: ports).renameFolder.execute(clients, to: "Customers")

        #expect(renamed == FolderPath(rawValue: "Work/Customers"))
        #expect(spies.files.calls.contains(.moveFolder(from: clients, to: renamed)))
        #expect(spies.files.paths == [VaultPath(rawValue: "Work/Customers/A.md")])
    }

    @Test func renameRefusesATopLevelFolder() async {
        await #expect(throws: VaultError.self) {
            try await UseCases(ports: ports).renameFolder.execute(work, to: "Job")
        }
    }
}
