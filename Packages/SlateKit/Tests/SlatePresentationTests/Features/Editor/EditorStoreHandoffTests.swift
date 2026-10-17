import Foundation
import SlateDomain
import SlateTestSupport
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct EditorStoreHandoffTests {
    private let harness = StoreHarness()

    @Test func copyPathAndLinkOfTheOpenNote() async throws {
        harness.seed("Notes/Plan.md", id: "p")
        try await harness.index()
        harness.navigator.select(NoteID(rawValue: "p"))
        await harness.editor.open(NoteID(rawValue: "p"))

        harness.editor.copyPath()
        harness.editor.copyLink()

        #expect(harness.copied == ["/vault/Notes/Plan.md", "slate://open?id=p"])
    }

    @Test func withoutANoteNothingIsCopied() {
        harness.editor.copyPath()
        harness.editor.copyLink()

        #expect(harness.copied.isEmpty)
    }
}
