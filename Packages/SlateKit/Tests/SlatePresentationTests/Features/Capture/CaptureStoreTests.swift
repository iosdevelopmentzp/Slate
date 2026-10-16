import Foundation
import SlateDomain
import SlateTestSupport
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct CaptureStoreTests {
    private let harness = StoreHarness()

    private var capture: CaptureStore {
        harness.capture
    }

    @Test func savingMakesANoteAndClearsTheDraft() async throws {
        capture.text = "Engine delegate must be weak\nand the other one"

        let document = try #require(await capture.save(to: .newNote))

        #expect(document.path == VaultPath(rawValue: "Inbox/Engine delegate must be weak.md"))
        #expect(capture.text.isEmpty)
        #expect(harness.toaster.text == "Saved to Inbox")
        #expect(harness.posted.contains(.indexUpdated))
        #expect(harness.navigator.selectedNote == nil)
    }

    @Test func aTicketMakesATask() async throws {
        capture.text = "ABC-2324 Profile screen leaks memory"

        #expect(capture.type == "task")
        let document = try #require(await capture.save(to: .newNote))
        #expect(document.path.space == SpaceName(rawValue: "Tasks"))
    }

    @Test func openSelectsTheNote() async throws {
        capture.text = "Look later"

        let document = try #require(await capture.save(to: .newNote, select: true))

        #expect(harness.navigator.selectedNote == document.id)
    }

    @Test func todayAppendsToTheLog() async throws {
        capture.text = "standup"

        let document = try #require(await capture.save(to: .today))

        #expect(document.path == VaultPath(rawValue: "Daily/2027-01-15.md"))
        #expect(harness.toaster.text == "Added to Today")
    }

    @Test func theChosenFolderAndKindAreUsed() async throws {
        capture.text = "Snippet text"
        capture.space = SpaceName(rawValue: "Notes")
        capture.typeOverride = "meeting"

        let document = try #require(await capture.save(to: .newNote))

        #expect(document.path.space == SpaceName(rawValue: "Notes"))
        #expect(document.header.type == "meeting")
    }

    @Test func emptyTextIsNotSaved() async {
        capture.text = "   "

        #expect(capture.canSave == false)
        #expect(await capture.save(to: .newNote) == nil)
    }

    @Test func prepareAsksForFocus() {
        let before = capture.focusToken

        capture.prepare()

        #expect(capture.focusToken == before + 1)
    }
}
