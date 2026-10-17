import Foundation
import SlateTestSupport
import Testing
@testable import SlateDomain

@Suite struct CreateFolderUseCaseTests {
    private let ports: Ports
    private let spies: PortSpies
    private let work = FolderPath(rawValue: "Work")
    private let clients = FolderPath(rawValue: "Work/Clients")

    init() {
        (ports, spies) = Ports.spies()
    }

    @Test func createMakesASubFolderWithACleanName() async throws {
        let created = try await UseCases(ports: ports).createFolder.execute(name: "  Clients ", in: work)

        #expect(created == clients)
        #expect(spies.files.calls == [.createFolder(clients)])
    }

    @Test func createRefusesANameThatExistsInTheSameFolder() async throws {
        spies.files.seedFolder(clients)

        await #expect(throws: VaultError.self) {
            try await UseCases(ports: ports).createFolder.execute(name: "clients", in: work)
        }
        _ = try await UseCases(ports: ports).createFolder.execute(name: "Clients", in: FolderPath(rawValue: "Home"))
    }
}
