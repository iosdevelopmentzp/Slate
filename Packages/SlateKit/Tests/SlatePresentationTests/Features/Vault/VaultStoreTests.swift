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
}
