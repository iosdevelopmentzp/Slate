import Foundation
import SlateDomain
import SlateTestSupport
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct EditorStoreTasksTests {
    private let harness = StoreHarness()

    private var editor: EditorStore {
        harness.editor
    }

    private func openTask() async throws -> VaultPath {
        let path = harness.seed("Tasks/ABC-1 Fix.md", id: "t", title: "ABC-1 Fix", type: "task", body: "Body")
        try await harness.index()
        harness.navigator.select(NoteID(rawValue: "t"))
        await editor.open(NoteID(rawValue: "t"))
        return path
    }

    @Test func statusIsWrittenToTheFile() async throws {
        let path = try await openTask()

        await editor.setStatus(.review)

        #expect(try await harness.document(at: path).header.status == "review")
        #expect(editor.document?.header.status == "review")
    }

    @Test func markDoneKeepsTypedText() async throws {
        let path = try await openTask()
        editor.text = "Body and more"

        await editor.markDone()

        let saved = try await harness.document(at: path)
        #expect(saved.header.status == "done")
        #expect(saved.body == "Body and more")
        #expect(harness.toaster.text == "Marked as Done")
    }

    @Test func templateIsInsertedWithItsValues() async throws {
        _ = try await openTask()
        harness.spies.templates.bodies["standup"] = "Standup {{date}} for {{title}}"

        await editor.insertTemplate(named: "standup")

        #expect(editor.insertion?.markdown == "Standup 2027-01-15 for ABC-1 Fix")
    }
}
