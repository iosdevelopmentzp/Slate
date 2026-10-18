import Foundation
import SlateDomain
import SlateMocks
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

    @Test func newProjectIsListedUnderProjectsAndShown() async {
        await vault.refresh()
        vault.startNewProject()

        #expect(vault.draftName == "New project")
        vault.draftName = "MyApp"
        let done = await vault.commitEdit()

        #expect(done)
        #expect(vault.projects.map(\.folder.rawValue) == ["MyApp"])
        #expect(vault.folderSpaces.contains { $0.folder.rawValue == "MyApp" } == false)
        #expect(harness.navigator.source == .space(SpaceName(rawValue: "MyApp")))
    }

    @Test func folderBecomesAProjectAndKeepsItsRepository() async {
        await vault.refresh()
        let inbox = SpaceName(rawValue: "Inbox")

        await vault.setProject(true, for: inbox)
        await vault.setRepositories(["/tmp/myapp"], for: inbox)

        #expect(vault.isProject(inbox))
        #expect(vault.projects.first?.project?.repositories == ["/tmp/myapp"])

        await vault.setProject(false, for: inbox)

        #expect(vault.isProject(inbox) == false)
    }

    @Test func moveStaysInsideFoldersOrProjects() async {
        await vault.refresh()
        await vault.setProject(true, for: SpaceName(rawValue: "Tasks"))
        await vault.setProject(true, for: SpaceName(rawValue: "Daily"))

        #expect(vault.canMove(SpaceName(rawValue: "Tasks"), by: -1) == false)
        #expect(vault.canMove(SpaceName(rawValue: "Notes"), by: -1))

        await vault.move(SpaceName(rawValue: "Notes"), by: -1)
        await vault.move(SpaceName(rawValue: "Tasks"), by: 1)

        #expect(vault.folderSpaces.map(\.folder.rawValue) == ["Notes", "Inbox", "Snippets", "Archive"])
        #expect(vault.projects.map(\.folder.rawValue) == ["Daily", "Tasks"])
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
        #expect(vault.confirmingDelete == FolderPath(rawValue: "Snippets"))
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
        try await waitUntil { harness.navigator.source == .space(SpaceName(rawValue: "Snippets")) }
    }

    @Test func theQuickNoteFolderIsNotDeleted() async {
        await vault.refresh()

        await vault.confirmDelete(SpaceName(rawValue: "Inbox"))

        #expect(vault.spaces.contains { $0.folder == SpaceName(rawValue: "Inbox") })
        #expect(harness.activity.events.map(\.title) == ["Cannot delete the folder"])
    }

    @Test func aSubFolderIsMadeInsideItsParentAndShown() async {
        await vault.refresh()

        vault.startNewFolder(in: FolderPath(rawValue: "Notes"))
        #expect(vault.editing == .newInside(FolderPath(rawValue: "Notes")))
        #expect(vault.isExpanded(FolderPath(rawValue: "Notes")))
        vault.draftName = "Swift"
        #expect(await vault.commitEdit())

        #expect(vault.subfolders == [FolderPath(rawValue: "Notes/Swift")])
        #expect(harness.navigator.source == .folder(FolderPath(rawValue: "Notes/Swift")))
        #expect(harness.keyValues.strings(forKey: "sidebar.expanded") == ["Notes"])
    }

    @Test func renamingASubFolderFollowsTheShownFolder() async throws {
        harness.spies.files.seedFolder(FolderPath(rawValue: "Notes/Swift/Actors"))
        await vault.refresh()
        vault.setExpanded(FolderPath(rawValue: "Notes/Swift"), true)
        harness.navigator.show(.folder(FolderPath(rawValue: "Notes/Swift/Actors")))

        vault.startRename(folder: FolderPath(rawValue: "Notes/Swift"))
        vault.draftName = "Swift 6"
        #expect(await vault.commitEdit())

        #expect(harness.navigator.source == .folder(FolderPath(rawValue: "Notes/Swift 6/Actors")))
        #expect(vault.isExpanded(FolderPath(rawValue: "Notes/Swift 6")))
    }

    @Test func deletingASubFolderMovesItsNotesUpAndOffersUndo() async throws {
        harness.seed("Notes/Swift/A.md", id: "a")
        try await harness.index()
        await vault.refresh()
        harness.navigator.show(.folder(FolderPath(rawValue: "Notes/Swift")))

        vault.requestDelete(folder: FolderPath(rawValue: "Notes/Swift"))
        #expect(vault.confirmingDelete == FolderPath(rawValue: "Notes/Swift"))
        await vault.confirmDelete(folder: FolderPath(rawValue: "Notes/Swift"))

        #expect(vault.subfolders.isEmpty)
        #expect(harness.navigator.source == .space(SpaceName(rawValue: "Notes")))
        #expect(harness.toaster.text == "Deleted Swift. 1 note moved to Notes.")

        harness.toaster.performAction()

        try await waitUntil { harness.spies.files.text(at: VaultPath(rawValue: "Notes/Swift/A.md")) != nil }
        try await waitUntil { harness.navigator.source == .folder(FolderPath(rawValue: "Notes/Swift")) }
    }
}
