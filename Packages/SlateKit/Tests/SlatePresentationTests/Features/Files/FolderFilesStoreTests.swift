import Foundation
import SlateDomain
import SlateMocks
import SlateTestSupport
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct FolderFilesStoreTests {
    private let harness = StoreHarness()
    private let folder = FolderPath(rawValue: "Tasks/ABC-123 Login")
    private let log = VaultPath(rawValue: "Tasks/ABC-123 Login/crash.log")

    private var files: FolderFilesStore {
        harness.files
    }

    @Test func showListsTheFilesButNotTheNotesOfTheFolder() async {
        harness.spies.files.seed(log, "boom")
        harness.spies.files.seed(VaultPath(rawValue: "Tasks/ABC-123 Login/ABC-123 Login.md"), "note")
        harness.spies.files.seed(VaultPath(rawValue: "Tasks/other.log"), "x")

        await files.show(folder)

        #expect(files.files.map(\.path) == [log])
    }

    @Test func noFolderShowsNoFiles() async {
        harness.spies.files.seed(log, "boom")
        await files.show(folder)

        await files.show(nil)

        #expect(files.files.isEmpty)
    }

    @Test func importAddsTheFilesToTheShownFolder() async throws {
        let temporary = try TemporaryDirectory()
        let source = try temporary.write("pdf", to: "spec.pdf")
        let note = try temporary.write("# Note", to: "note.md")
        await files.show(folder)

        let added = await files.importFiles([source, note])

        #expect(added == [VaultPath(rawValue: "Tasks/ABC-123 Login/spec.pdf")])
        #expect(files.files.map(\.path) == added)
        #expect(harness.toaster.text == "Added spec.pdf")
    }

    @Test func renameKeepsTheExtensionWhenItIsLeftOut() async {
        harness.spies.files.seed(log, "boom")
        await files.show(folder)

        files.startRename(log)
        files.draftName = "first crash"
        let done = await files.commitRename()

        #expect(done)
        #expect(files.renaming == nil)
        #expect(files.files.map(\.path.fileName) == ["first crash.log"])
    }

    @Test func emptyNameIsRefused() async {
        harness.spies.files.seed(log, "boom")
        await files.show(folder)

        files.startRename(log)
        files.draftName = " "
        let done = await files.commitRename()

        #expect(done == false)
        #expect(files.renaming == log)
    }

    @Test func trashOffersUndoThatBringsTheFileBack() async throws {
        harness.spies.files.seed(log, "boom")
        await files.show(folder)

        await files.trash(log)

        #expect(files.files.isEmpty)
        #expect(harness.toaster.actionTitle == "Undo")
        harness.toaster.performAction()
        try await waitUntil { files.files.map(\.path) == [log] }
    }

    @Test func quickLookOpenAndRevealUseTheFileInTheNotesFolder() async {
        await files.quickLook(log)
        await files.open(log)
        await files.reveal(log)

        let url = URL(fileURLWithPath: "/vault/Tasks/ABC-123 Login/crash.log")
        #expect(harness.spies.workspace.calls == [.quickLook(url), .open(url), .reveal(url)])
    }

    @Test func saveToDownloadsCopiesTheFile() async {
        await files.saveToDownloads(log)

        #expect(harness.spies.exporter.copied == [URL(fileURLWithPath: "/vault/Tasks/ABC-123 Login/crash.log")])
    }

    @Test func aChangeInTheFolderRefreshes() async throws {
        await files.show(folder)
        harness.spies.files.seed(log, "boom")

        harness.events.post(.vaultChanged([log]))

        try await waitUntil { files.files.map(\.path) == [log] }
    }
}
