import Foundation
import SlateDomain
import SlateTestSupport
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct VaultStoreTests {
    private let harness = StoreHarness()

    private var vault: VaultStore {
        harness.vault
    }

    @Test func refreshLoadsTheFolders() async {
        await vault.refresh()

        #expect(vault.spaces.map(\.folder.rawValue) == ["Inbox", "Tasks", "Notes", "Daily", "Snippets", "Archive"])
    }

    @Test func createShowsTheNewFolder() async {
        let created = await vault.create(named: "Reading")

        #expect(created)
        #expect(vault.spaces.last?.folder == SpaceName(rawValue: "Reading"))
        #expect(harness.navigator.source == .space(SpaceName(rawValue: "Reading")))
    }

    @Test func failedCreateIsLogged() async {
        let created = await vault.create(named: "Inbox")

        #expect(created == false)
        #expect(harness.activity.events.map(\.title) == ["Cannot create the folder"])
    }

    @Test func renameFollowsTheShownFolderAndAnnouncesTheRescan() async {
        await vault.refresh()
        harness.navigator.show(.space(SpaceName(rawValue: "Archive")))

        await vault.rename(SpaceName(rawValue: "Archive"), to: "Done")

        #expect(harness.navigator.source == .space(SpaceName(rawValue: "Done")))
        #expect(harness.posted.suffix(2) == [.indexUpdated, .vaultRescanned])
    }

    @Test func moveAndIconAreSaved() async {
        await vault.refresh()

        await vault.move(SpaceName(rawValue: "Tasks"), by: -1)
        await vault.setIcon("star", for: SpaceName(rawValue: "Inbox"))

        #expect(harness.spies.config.config.spaces.prefix(2).map(\.folder.rawValue) == ["Tasks", "Inbox"])
        #expect(harness.spies.config.config.spaces[1].icon == "star")
        #expect(vault.canMove(SpaceName(rawValue: "Tasks"), by: -1) == false)
    }

    @Test func spacesChangedEventRefreshes() async throws {
        _ = vault
        harness.spies.config.config = SpacesConfig(spaces: [Space(folder: SpaceName(rawValue: "Only"))])

        harness.events.post(.spacesChanged)

        try await waitUntil { vault.spaces.map(\.folder.rawValue) == ["Only"] }
    }

    @Test func newFolderStartsWithAFreeNameAndCommitMakesIt() async {
        await vault.create(named: "New folder")

        vault.startNewFolder()
        #expect(vault.editing == .new)
        #expect(vault.draftName == "New folder 2")

        vault.draftName = "Recipes"
        #expect(await vault.commitEdit())

        #expect(vault.editing == nil)
        #expect(vault.spaces.last?.folder == SpaceName(rawValue: "Recipes"))
        #expect(harness.navigator.source == .space(SpaceName(rawValue: "Recipes")))
    }

    @Test func renameThroughTheFieldKeepsEditingOnAFailure() async {
        await vault.refresh()

        vault.startRename(SpaceName(rawValue: "Archive"))
        vault.draftName = "Inbox"
        let done = await vault.commitEdit()

        #expect(done == false)
        #expect(vault.editing == .rename(SpaceName(rawValue: "Archive")))
        #expect(harness.toaster.text == "Inbox already exists. Choose another name.")
    }

    @Test func colourIsSaved() async {
        await vault.refresh()

        await vault.setColor(.pink, for: SpaceName(rawValue: "Notes"))

        #expect(harness.spies.config.config.space(SpaceName(rawValue: "Notes"))?.color == .pink)
    }

    @Test func deleteAsksFirstThenMovesTheNotesAndOffersUndo() async throws {
        harness.seed("Snippets/A.md", id: "a")
        try await harness.index()
        await vault.refresh()
        harness.navigator.show(.space(SpaceName(rawValue: "Snippets")))

        vault.requestDelete(SpaceName(rawValue: "Snippets"))
        #expect(vault.confirmingDelete == SpaceName(rawValue: "Snippets"))
        await vault.confirmDelete(SpaceName(rawValue: "Snippets"))

        #expect(vault.confirmingDelete == nil)
        #expect(vault.spaces.contains { $0.folder == SpaceName(rawValue: "Snippets") } == false)
        #expect(harness.navigator.source == .space(SpaceName(rawValue: "Inbox")))
        #expect(harness.posted.contains(.noteMoved(from: VaultPath(rawValue: "Snippets/A.md"), to: VaultPath(rawValue: "Inbox/A.md"))))
        #expect(harness.toaster.text == "Deleted Snippets. 1 note moved to Inbox.")
        #expect(harness.toaster.actionTitle == "Undo")

        harness.toaster.performAction()

        try await waitUntil { vault.spaces.contains { $0.folder == SpaceName(rawValue: "Snippets") } }
        try await waitUntil { harness.spies.files.text(at: VaultPath(rawValue: "Snippets/A.md")) != nil }
        #expect(harness.navigator.source == .space(SpaceName(rawValue: "Snippets")))
    }

    @Test func theQuickNoteFolderIsNotDeleted() async {
        await vault.refresh()

        await vault.confirmDelete(SpaceName(rawValue: "Inbox"))

        #expect(vault.spaces.contains { $0.folder == SpaceName(rawValue: "Inbox") })
        #expect(harness.activity.events.map(\.title) == ["Cannot delete the folder"])
    }
}
