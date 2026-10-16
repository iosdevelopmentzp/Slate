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

        let document = try #require(await capture.save())

        #expect(document.path == VaultPath(rawValue: "Inbox/Engine delegate must be weak.md"))
        #expect(capture.text.isEmpty)
        #expect(harness.toaster.text == "Saved to Inbox")
        #expect(harness.posted.contains(.indexUpdated))
        #expect(harness.navigator.selectedNote == nil)
    }

    @Test func aTicketKeyStaysAPlainNote() async throws {
        capture.text = "ABC-2324 Profile screen leaks memory"

        let document = try #require(await capture.save())

        #expect(document.path.space == SpaceName(rawValue: "Inbox"))
        #expect(document.header.type == NoteType.defaultName)
    }

    @Test func openSelectsTheNote() async throws {
        capture.text = "Look later"

        let document = try #require(await capture.save(select: true))

        #expect(harness.navigator.selectedNote == document.id)
    }

    @Test func theChosenFolderIsUsed() async throws {
        capture.text = "Idea"
        capture.space = SpaceName(rawValue: "Notes")

        let document = try #require(await capture.save())

        #expect(document.path.space == SpaceName(rawValue: "Notes"))
    }

    @Test func emptyTextIsNotSaved() async {
        capture.text = "   "

        #expect(capture.canSave == false)
        #expect(await capture.save() == nil)
    }

    @Test func prepareAsksForFocus() {
        let before = capture.focusToken

        capture.prepare()

        #expect(capture.focusToken == before + 1)
    }
}
