import Foundation
import SlateDomain
import SlateTestSupport
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct NoteListStoreURLTests {
    private let harness = StoreHarness()

    @Test func newFromAURLMakesAndSelectsTheNote() async throws {
        await harness.noteList.create(NoteDraft(title: "Hi", body: "Text\n"))

        let note = try #require(harness.spies.index.indexed[VaultPath(rawValue: "Inbox/Hi.md")])
        #expect(harness.navigator.selectedNote == note.id)
    }

    @Test func openThatMakesANoteSelectsIt() async throws {
        await harness.noteList.open(.ticket("ABC-5"))

        let made = try #require(harness.spies.index.indexed[VaultPath(rawValue: "Tasks/ABC-5.md")])
        #expect(harness.navigator.selectedNote == made.id)
    }

    @Test func openOfAMissingNoteSaysSo() async {
        await harness.noteList.open(.title("Nothing like this"))

        #expect(harness.toaster.text == "Slate found no such note")
    }

    @Test func openByTitleSelectsIt() async throws {
        harness.seed("Notes/Plan B.md", id: "p", title: "Plan B")
        try await harness.index()
        await harness.noteList.refresh()

        await harness.noteList.open(.title("plan b"))

        #expect(harness.navigator.selectedNote == NoteID(rawValue: "p"))
    }

    @Test func appendFromAURLWritesToToday() async throws {
        await harness.noteList.append("from a script", to: .today, section: nil)

        #expect(harness.spies.files.text(at: VaultPath(rawValue: "Daily/2027-01-15.md"))?.contains("from a script") == true)
        #expect(harness.toaster.text == "Added to 2027-01-15")
    }

    @Test func servicesTextBecomesANote() async throws {
        await harness.capture.addFromService("Selected text\nfrom Safari")

        #expect(harness.spies.index.indexed[VaultPath(rawValue: "Inbox/Selected text.md")] != nil)
    }
}
