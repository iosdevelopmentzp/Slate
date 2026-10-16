import Foundation
import SlateTestSupport
import Testing
@testable import SlateDomain

@Suite struct OpenTargetUseCaseTests {
    @Test func knownIDIsFound() async throws {
        let (ports, spies) = Ports.spies()
        let useCases = UseCases(ports: ports)
        spies.files.seed(VaultPath(rawValue: "Notes/A.md"), NoteText.make(id: "a", title: "A", body: ""))
        _ = try await useCases.reindex.execute(.all)

        #expect(try await useCases.openTarget.execute(.id(NoteID(rawValue: "a"))) == .found(NoteID(rawValue: "a")))
    }

    @Test func unknownIDIsMissing() async throws {
        let (ports, _) = Ports.spies()

        #expect(try await UseCases(ports: ports).openTarget.execute(.id(NoteID(rawValue: "nope"))) == .missing)
    }

    @Test func titleMatchesWithoutCase() async throws {
        let (ports, spies) = Ports.spies()
        let useCases = UseCases(ports: ports)
        spies.files.seed(VaultPath(rawValue: "Notes/Plan B.md"), NoteText.make(id: "p", title: "Plan B", body: ""))
        _ = try await useCases.reindex.execute(.all)

        #expect(try await useCases.openTarget.execute(.title("plan b")) == .found(NoteID(rawValue: "p")))
    }

    @Test func unknownTicketMakesANote() async throws {
        let (ports, spies) = Ports.spies()

        let outcome = try await UseCases(ports: ports).openTarget.execute(.ticket("ABC-5"))

        guard case .created(let created) = outcome else {
            Issue.record("Expected a new note, got \(outcome)")
            return
        }
        #expect(created.document.header.ticket == "ABC-5")
        #expect(spies.index.indexed[created.document.path] != nil)
    }
}
