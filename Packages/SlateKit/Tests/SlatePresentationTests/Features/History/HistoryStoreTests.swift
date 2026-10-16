import Foundation
import SlateDomain
import SlateTestSupport
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct HistoryStoreTests {
    private let harness = StoreHarness()

    @Test func snapshotNowRecordsTheTime() async throws {
        harness.spies.history.seed(Snapshot(hash: "abc1234", date: Date(timeIntervalSince1970: 5), message: "x"), of: VaultPath(rawValue: "Notes/A.md"), text: "")

        await harness.history.snapshotNow()

        #expect(harness.history.lastSnapshot == Date(timeIntervalSince1970: 5))
        #expect(harness.history.push == .notConfigured)
    }

    @Test func aFailedPushShowsInActivity() async throws {
        harness.history.settings.remote = "origin"
        harness.history.saveSettings()
        harness.history.stop()
        harness.spies.history.pushError = .scripted("offline")

        await harness.history.snapshotNow()

        #expect(harness.activity.events.first?.title == "Push of the history failed")
    }

    @Test func versionsLoadForTheOpenNote() async throws {
        let path = VaultPath(rawValue: "Notes/A.md")
        harness.spies.history.seed(Snapshot(hash: "abc1234", date: Date(), message: "x"), of: path, text: "")

        await harness.history.load(for: path)

        #expect(harness.history.snapshots.map(\.hash) == ["abc1234"])
    }

    @Test func restoreRewritesTheFileAndTellsTheEditor() async throws {
        let path = harness.seed("Notes/A.md", id: "a", title: "A", body: "now")
        try await harness.index()
        let snapshot = Snapshot(hash: "abc1234", date: Date(), message: "x")
        harness.spies.history.seed(snapshot, of: path, text: NoteText.make(id: "a", title: "A", body: "before"))
        harness.clearPosted()

        await harness.history.restore(snapshot, of: path)

        #expect(try await harness.document(at: path).body == "before")
        #expect(harness.posted.contains(.vaultChanged([path])))
        #expect(harness.toaster.text == "Restored the earlier version")
    }

    @Test func purgeLogsWhatWasEmptied() async throws {
        harness.spies.trash.seed(TrashItem(path: VaultPath(rawValue: "Inbox/Old.md"), originalPath: VaultPath(rawValue: "Inbox/Old.md"), trashedAt: harness.spies.clock.current.addingTimeInterval(-60 * 86_400)))

        await harness.history.purgeNow()

        #expect(harness.activity.events.first?.title == "Emptied old notes from the Trash")
    }

    @Test func quitJobIsNilWhenHistoryIsOff() {
        harness.history.settings.isEnabled = false

        #expect(harness.history.quitJob() == nil)
    }

    @Test func theBackupAddressIsTrimmedAndSaved() {
        harness.history.setRemote("  git@example.com:notes.git \n")
        harness.history.stop()

        #expect(harness.history.settings.remote == "git@example.com:notes.git")
        #expect(HistorySettings.load(from: harness.keyValues).remote == "git@example.com:notes.git")
    }

    @Test func backUpNowPushesAndSaysSo() async {
        harness.history.setRemote("git@example.com:notes.git")
        harness.history.stop()

        await harness.history.backUpNow()

        #expect(harness.history.push == .pushed)
        #expect(harness.toaster.text == "Backed up")
    }

    @Test func backUpNowWithoutAnAddressAsksForOne() async {
        await harness.history.backUpNow()

        #expect(harness.toaster.text == "Add a git address to back up to.")
    }

    @Test func aFailedBackupPointsToActivity() async {
        harness.history.setRemote("git@example.com:notes.git")
        harness.history.stop()
        harness.spies.history.pushError = .scripted("offline")

        await harness.history.backUpNow()

        #expect(harness.toaster.text == "The backup failed. See Activity in Settings.")
    }
}
