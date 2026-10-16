import Foundation
import SlateTestSupport
import Testing
@testable import SlateDomain

@Suite struct UpdateHeaderUseCaseTests {
    @Test func changesTheHeaderAndKeepsTheBody() async throws {
        let (ports, spies) = Ports.spies()
        let path = VaultPath(rawValue: "Inbox/A.md")
        spies.files.seed(path, NoteText.make(id: "a", title: "A", body: "Body"))

        let result = try await UseCases(ports: ports).updateHeader.execute(path) { $0.pinned = true }

        #expect(result.document?.header.pinned == true)
        #expect(result.document?.body == "Body")
        #expect(spies.files.text(at: path)?.contains("pinned: true") == true)
    }
}
