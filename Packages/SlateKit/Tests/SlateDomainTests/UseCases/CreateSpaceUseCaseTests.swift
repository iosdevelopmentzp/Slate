import Foundation
import SlateTestSupport
import Testing
@testable import SlateDomain

@Suite struct CreateSpaceUseCaseTests {
    @Test func createsTheFolderAndAddsItToTheConfig() async throws {
        let (ports, spies) = Ports.spies()

        let space = try await UseCases(ports: ports).createSpace.execute(name: " Reading ")

        #expect(space == SpaceName(rawValue: "Reading"))
        #expect(spies.files.folderNames == [space])
        #expect(spies.config.config.spaces.last == Space(folder: space, icon: "folder", defaultType: "note"))
    }

    @Test func existingNameIsRejectedCaseInsensitively() async throws {
        let (ports, _) = Ports.spies()

        await #expect(throws: VaultError.alreadyExists("inbox")) {
            try await UseCases(ports: ports).createSpace.execute(name: "inbox")
        }
    }

    @Test func emptyNameIsRejected() async throws {
        let (ports, _) = Ports.spies()

        await #expect(throws: VaultError.invalidName("  ")) {
            try await UseCases(ports: ports).createSpace.execute(name: "  ")
        }
    }
}
