import Foundation
import SlateDomain
import SlateTestSupport
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct VaultChangeFeedTests {
    @Test func startScansTheVaultThenForwardsChanges() async throws {
        let harness = StoreHarness()
        let path = harness.seed("Inbox/A.md", id: "a")

        harness.feed.start()
        try await waitUntil { harness.posted.contains(.indexUpdated) }
        #expect(harness.spies.index.indexed.keys.contains(path))

        harness.clearPosted()
        harness.seed("Inbox/A.md", id: "a", body: "changed")
        try await waitUntil { harness.spies.watcher.subscriberCount == 1 }
        harness.spies.watcher.send(.paths([path]))
        try await waitUntil { harness.posted.contains(.vaultChanged([path])) }

        #expect(harness.posted == [.indexUpdated, .vaultChanged([path])])
        harness.feed.stop()
    }

    @Test func rescanAnnouncesFoldersAndTheRescan() async throws {
        let harness = StoreHarness()

        await harness.feed.apply(.rescan)

        #expect(harness.posted == [.indexUpdated, .spacesChanged, .vaultRescanned])
    }

    @Test func unreadableNoteIsLogged() async throws {
        let harness = StoreHarness()
        try await harness.spies.files.create(VaultPath(rawValue: "Inbox/Bad.md"), data: Data([0xFF, 0xFE, 0xD8]))

        await harness.feed.apply(.rescan)

        #expect(harness.activity.events.map(\.detail) == ["Inbox/Bad.md"])
    }
}
