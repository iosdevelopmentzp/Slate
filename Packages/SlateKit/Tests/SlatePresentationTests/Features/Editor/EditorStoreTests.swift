import Foundation
import SlateDomain
import SlateTestSupport
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct EditorStoreTests {
    private let harness = StoreHarness()

    private var editor: EditorStore {
        harness.editor
    }

    private func open(_ path: String, id: String? = "a", title: String? = nil, body: String = "Body") async throws -> VaultPath {
        let vaultPath = harness.seed(path, id: id, title: title, body: body)
        try await harness.index()
        let summary = try #require(try await harness.ports.index.summaries(space: nil).first { $0.path == vaultPath })
        harness.navigator.select(summary.id)
        await editor.open(summary.id)
        return vaultPath
    }

    private func text(at path: VaultPath) -> String {
        harness.spies.files.text(at: path) ?? ""
    }

    @Test func openLoadsTheFile() async throws {
        let path = try await open("Inbox/A.md", title: "Alpha")

        #expect(editor.document?.path == path)
        #expect(editor.text == "Body")
        #expect(editor.title == "Alpha")
        #expect(editor.isDirty == false)
    }

    @Test func setStatusWritesTheHeader() async throws {
        let path = try await open("Inbox/A.md")

        await editor.setStatus(.done)

        #expect(editor.document?.header.status == "done")
        #expect(text(at: path).contains("status: done"))
    }

    @Test func typingSavesAfterAShortPause() async throws {
        let path = try await open("Inbox/A.md")

        editor.text = "Body more"

        #expect(editor.isDirty)
        try await waitUntil { self.text(at: path).hasSuffix("Body more") }
        try await waitUntil { editor.isDirty == false }
        #expect(editor.saveState == .saved(harness.spies.clock.current))
        #expect(harness.posted.contains(.noteSaved(NoteID(rawValue: "a"))))
    }

    @Test func flushSavesAtOnce() async throws {
        let path = try await open("Inbox/A.md")
        editor.text = "Now"

        await editor.flush()

        #expect(text(at: path).hasSuffix("---\nNow"))
    }

    @Test func titleChangeRenamesTheFile() async throws {
        let path = try await open("Inbox/A.md", title: "A")

        editor.editTitle("Better name")
        await editor.flush()

        let target = VaultPath(rawValue: "Inbox/Better name.md")
        #expect(editor.document?.path == target)
        #expect(harness.spies.files.paths == [target])
        #expect(harness.posted.contains(.noteMoved(from: path, to: target)))
        #expect(text(at: target).contains("title: Better name"))
    }

    @Test func emptyTitleSavesAsUntitled() async throws {
        _ = try await open("Inbox/A.md", title: "A")

        editor.editTitle("")
        await editor.flush()

        #expect(editor.document?.path == VaultPath(rawValue: "Inbox/Untitled.md"))
    }

    @Test func newUntitledNoteTakesItsTitleFromTheFirstLine() async throws {
        _ = editor
        await harness.noteList.createNote()
        let id = try #require(harness.navigator.selectedNote)
        await editor.open(id)
        #expect(editor.followsBody)
        #expect(editor.titleFieldText == "")
        #expect(editor.titleFocusToken == 1)

        editor.text = "Engine delegate must be weak\nmore"
        await editor.flush()

        #expect(editor.document?.path == VaultPath(rawValue: "Inbox/Engine delegate must be weak.md"))
        #expect(editor.title == "Engine delegate must be weak")
        #expect(editor.followsBody)
    }

    @Test func typingATitleStopsFollowingTheBody() async throws {
        _ = editor
        await harness.noteList.createNote()
        await editor.open(try #require(harness.navigator.selectedNote))

        editor.editTitle("Chosen")
        editor.text = "Something else"
        await editor.flush()

        #expect(editor.followsBody == false)
        #expect(editor.document?.path == VaultPath(rawValue: "Inbox/Chosen.md"))
    }

    @Test func externalChangeReloadsACleanEditor() async throws {
        let path = try await open("Inbox/A.md")
        harness.seed(path.rawValue, id: "a", title: "A", body: "From Obsidian")

        harness.events.post(.vaultChanged([path]))

        try await waitUntil { editor.text == "From Obsidian" }
        #expect(editor.hasConflict == false)
    }

    @Test func externalBodyChangeWhileTypingIsAConflictAndNothingIsOverwritten() async throws {
        let path = try await open("Inbox/A.md")
        editor.text = "Mine"
        harness.seed(path.rawValue, id: "a", title: "A", body: "Theirs")

        harness.events.post(.vaultChanged([path]))
        try await waitUntil { editor.hasConflict }
        await editor.flush()

        #expect(text(at: path).hasSuffix("Theirs"))
        #expect(editor.text == "Mine")
    }

    @Test func keepMineOverwritesAfterAConflict() async throws {
        let path = try await open("Inbox/A.md")
        editor.text = "Mine"
        harness.seed(path.rawValue, id: "a", title: "A", body: "Theirs")
        harness.events.post(.vaultChanged([path]))
        try await waitUntil { editor.hasConflict }

        await editor.keepMine()

        #expect(editor.hasConflict == false)
        #expect(text(at: path).hasSuffix("Mine"))
    }

    @Test func takeTheirsDropsTheLocalText() async throws {
        let path = try await open("Inbox/A.md")
        editor.text = "Mine"
        harness.seed(path.rawValue, id: "a", title: "A", body: "Theirs")
        harness.events.post(.vaultChanged([path]))
        try await waitUntil { editor.hasConflict }

        await editor.takeTheirs()

        #expect(editor.text == "Theirs")
        #expect(editor.isDirty == false)
    }

    @Test func headerOnlyChangeWhileTypingIsAdopted() async throws {
        let path = try await open("Inbox/A.md")
        editor.text = "Mine"
        harness.seed(path.rawValue, id: "a", title: "A", pinned: true, body: "Body")

        harness.events.post(.vaultChanged([path]))
        try await waitUntil { editor.document?.header.pinned == true }
        await editor.flush()

        #expect(editor.hasConflict == false)
        let saved = text(at: path)
        #expect(saved.contains("pinned: true"))
        #expect(saved.hasSuffix("Mine"))
    }

    @Test func moveAndTrashEventsFollowTheOpenNote() async throws {
        let path = try await open("Inbox/A.md")
        let target = VaultPath(rawValue: "Archive/A.md")

        harness.events.post(.noteMoved(from: path, to: target))
        #expect(editor.document?.path == target)

        harness.events.post(.noteTrashed(target))
        #expect(editor.document == nil)
    }

    @Test func firstSaveOfAFileWithoutAnIDKeepsItSelected() async throws {
        let path = harness.seed("Inbox/Plain.md", body: "x")
        harness.spies.files.seed(path, "Plain text")
        try await harness.index()
        let pathID = NoteID.forPath(path)
        harness.navigator.select(pathID)
        await editor.open(pathID)

        editor.text = "Plain text more"
        await editor.flush()

        let newID = try #require(editor.document?.header.id)
        #expect(harness.navigator.selectedNote == newID)
    }

    @Test func openingAnotherNoteSavesTheFirst() async throws {
        let first = try await open("Inbox/A.md")
        editor.text = "Changed"
        let second = try await open("Inbox/B.md", id: "b")

        #expect(text(at: first).hasSuffix("Changed"))
        #expect(editor.document?.path == second)
    }

    @Test func pendingSaveWritesWithoutTheStore() async throws {
        let path = try await open("Inbox/A.md")
        editor.text = "On quit"

        let job = try #require(editor.pendingSave())
        await job()

        #expect(text(at: path).hasSuffix("On quit"))
    }

    @Test func cleanEditorHasNoPendingSave() async throws {
        _ = try await open("Inbox/A.md")

        #expect(editor.pendingSave() == nil)
    }
}
