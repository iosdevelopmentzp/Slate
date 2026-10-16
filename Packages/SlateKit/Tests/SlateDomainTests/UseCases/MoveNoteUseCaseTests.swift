import Foundation
import SlateTestSupport
import Testing
@testable import SlateDomain

@Suite struct MoveNoteUseCaseTests {
    private let ports: Ports
    private let spies: PortSpies

    init() {
        (ports, spies) = Ports.spies()
    }

    @Test func movesToDepthOneOfTheTargetWithAUniqueStem() async throws {
        let source = VaultPath(rawValue: "Notes/Swift/Actors.md")
        spies.files.seed(source, NoteText.make(id: "a", title: "Actors", body: ""))
        spies.files.seed(VaultPath(rawValue: "Archive/Actors.md"), "x")

        let target = try await UseCases(ports: ports).move.execute(source, to: SpaceName(rawValue: "Archive"))

        #expect(target == VaultPath(rawValue: "Archive/Actors 2.md"))
        #expect(spies.index.calls == [.remove(source), .upsert(target)])
    }

    @Test func noteAlreadyAtTheTopOfTheSpaceStays() async throws {
        let source = VaultPath(rawValue: "Inbox/A.md")
        spies.files.seed(source, "x")

        let target = try await UseCases(ports: ports).move.execute(source, to: SpaceName(rawValue: "Inbox"))

        #expect(target == source)
        #expect(spies.files.calls.isEmpty)
    }

    @Test func archiveUsesTheArchiveSpaceFromTheConfig() async throws {
        let source = VaultPath(rawValue: "Inbox/A.md")
        spies.files.seed(source, NoteText.make(id: "a", title: "A", body: ""))

        let target = try await UseCases(ports: ports).archive.execute(source)

        #expect(target == VaultPath(rawValue: "Archive/A.md"))
    }
}
