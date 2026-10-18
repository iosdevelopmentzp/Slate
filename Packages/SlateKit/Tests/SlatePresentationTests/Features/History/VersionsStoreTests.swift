import Foundation
import SlateDomain
import SlateMocks
import SlateTestSupport
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct VersionsStoreTests {
    private let harness = StoreHarness()
    private let old = Snapshot(hash: "abc1234", date: Date(timeIntervalSince1970: 1_800_000_000), message: "snapshot: 1 file")

    private var versions: VersionsStore {
        harness.versions
    }

    @Test func aNoteVersionShowsItsBodyAndWhatChangedSince() async throws {
        let path = harness.seed("Notes/A.md", id: "a", title: "A", body: "one\nthree\n")
        harness.spies.history.seed(old, of: path, text: NoteText.make(id: "a", title: "A", body: "one\ntwo\n"))

        await versions.select(old, of: path)

        let preview = try #require(versions.preview)
        #expect(preview.text == "one\ntwo\n")
        #expect(preview.diff == [DiffLine(.same, "one"), DiffLine(.removed, "two"), DiffLine(.added, "three")])
        #expect(preview.added == 1)
        #expect(preview.removed == 1)
    }

    @Test func aNamedVersionIsASnapshotWithTheName() async {
        let saved = await versions.saveVersion("  before refactor\n")

        #expect(saved)
        #expect(harness.spies.history.calls.contains(.snapshot("version: before refactor")))
        #expect(harness.toaster.text == "Saved the version \u{201C}before refactor\u{201D}")
    }

    @Test func nothingToSaveSaysSoAndAnEmptyNameDoesNothing() async {
        harness.spies.history.hasChanges = false

        #expect(await versions.saveVersion("x") == false)
        #expect(harness.toaster.text == "Nothing changed since the last version")
        #expect(await versions.saveVersion("  ") == false)
    }

    @Test func aFileVersionOpensInQuickLookFromATemporaryCopy() async {
        let path = VaultPath(rawValue: "MyApp/screen.png")
        harness.spies.history.seed(old, of: path, text: "png")

        await versions.loadFileVersions(path)
        await versions.quickLook(old, of: path)

        #expect(versions.fileVersions == [old])
        let name = VersionsStore.versionName(of: path, at: old.date)
        #expect(name.hasPrefix("screen "))
        #expect(name.hasSuffix(".png"))
        #expect(harness.spies.exporter.saved["tmp/\(name)"] == Data("png".utf8))
        #expect(harness.spies.workspace.calls == [.quickLook(URL(fileURLWithPath: "/tmp").appendingPathComponent(name))])
    }

    @Test func restoringAFileWritesItAndAnnouncesTheChange() async {
        let path = VaultPath(rawValue: "MyApp/state.json")
        harness.spies.files.seed(path, "new")
        harness.spies.history.seed(old, of: path, text: "old")

        await versions.restoreFile(old, of: path)

        #expect(harness.spies.files.text(at: path) == "old")
        #expect(harness.posted.contains(.vaultChanged([path])))
    }

    @Test func changesOfAFolderAreLoaded() async {
        let change = SnapshotChange(snapshot: old, files: [ChangedFile(path: VaultPath(rawValue: "MyApp/a.md"), kind: .added)])
        harness.spies.history.changeList = [change]

        await versions.loadChanges(in: FolderPath(rawValue: "MyApp"))

        #expect(versions.changes == [change])
        #expect(harness.spies.history.calls.contains(.changes(FolderPath(rawValue: "MyApp"))))
    }

    @Test func clearingAsksFirstThenClearsTheChosenFolder() async {
        let folder = FolderPath(rawValue: "MyApp")
        versions.requestClear(.folder(folder))
        #expect(versions.confirmingClear == .folder(folder))

        await versions.confirmClear()

        #expect(versions.confirmingClear == nil)
        #expect(harness.spies.history.calls.contains(.clear(folder)))
        #expect(harness.toaster.text == "Cleared the history of MyApp")
    }

    @Test func cancelLeavesTheHistoryAlone() async {
        versions.requestClear(.everything)
        versions.cancelClear()

        await versions.confirmClear()

        #expect(harness.spies.history.calls.contains(.clear(nil)) == false)
    }
}
