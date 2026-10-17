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

    @Test func changesByAnAgentShowInActivityOnce() async throws {
        let harness = StoreHarness()
        let path = harness.seed("Notes/Groceries.md", id: "g")
        let feed = harness.feed
        try await harness.spies.agentChanges.record(AgentChange(date: harness.ports.clock.now().addingTimeInterval(-60), tool: "append_to_note", title: "Old", path: path))
        try await harness.spies.agentChanges.record(AgentChange(date: harness.ports.clock.now().addingTimeInterval(1), tool: "append_to_note", title: "Groceries", path: path))

        await feed.apply(.paths([path]))
        await feed.apply(.paths([path]))

        #expect(harness.activity.events.map(\.title) == ["Changed by an agent: Groceries"])
        #expect(harness.activity.events.map(\.detail) == ["Notes/Groceries.md"])
    }
}
