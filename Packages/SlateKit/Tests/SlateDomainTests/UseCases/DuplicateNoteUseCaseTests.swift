import Foundation
import SlateTestSupport
import Testing
@testable import SlateDomain

@Suite struct DuplicateNoteUseCaseTests {
    @Test func copyGetsANewIDAndANumberedFile() async throws {
        let (ports, spies) = Ports.spies()
        let source = VaultPath(rawValue: "Inbox/A.md")
        spies.files.seed(source, NoteText.make(id: "a", title: "A", body: "Body"))

        let copy = try await UseCases(ports: ports).duplicate.execute(source)

        #expect(copy.path == VaultPath(rawValue: "Inbox/A 2.md"))
        #expect(copy.header.id != NoteID(rawValue: "a"))
        #expect(copy.title == "A")
        #expect(copy.body == "Body")
        #expect(copy.header.created == spies.clock.current)
        #expect(spies.index.calls == [.upsert(copy.path)])
    }
}
