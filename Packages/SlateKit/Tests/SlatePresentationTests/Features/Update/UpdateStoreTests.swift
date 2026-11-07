import Foundation
import SlateDomain
import SlateTestSupport
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct UpdateStoreTests {
    private let harness = StoreHarness()
    private let build = InstalledBuild(commit: "a1b2c3d4e5f6", branch: "main", source: "/s/source")
    private let commits = [UpdateCommit(hash: "b2c3d4e", subject: "feat: new")]

    private var updater: SpyAppUpdater { harness.spies.updater }
    private var store: UpdateStore { harness.updates }

    @Test func newCommitsShowTheButton() async {
        updater.build = build
        updater.commits = commits

        await store.check()

        #expect(store.state == .available(commits))
    }

    @Test func aDevelopmentBuildIsNeverChecked() async {
        await store.check()

        #expect(updater.checks == 0)
        #expect(store.state == .idle)
    }

    @Test func aFinishedUpdateSaysSoOnceAtLaunch() async {
        updater.build = build
        updater.currentStatus = UpdateStatus(phase: .done, startedAt: .distantPast, commit: build.commit)

        await store.launch()

        #expect(harness.toaster.text == "Updated to a1b2c3d")
        #expect(updater.currentStatus == nil)
    }

    @Test func anUpdateThatStoppedIsAFailure() async {
        updater.build = build
        updater.currentStatus = UpdateStatus(phase: .building, startedAt: .distantPast)
        updater.running = false

        await store.launch()

        #expect(store.state == .failed("The last update stopped before it ended."))
    }

    @Test func updateStartsTheScriptAndFollowsItToTheFailure() async {
        updater.build = build
        updater.commits = commits
        await store.check()
        updater.statusAfterStart = UpdateStatus(phase: .failed, startedAt: .distantPast, message: "The build failed.")

        await store.update()

        #expect(updater.started == [build])
        #expect(store.state == .failed("The build failed."))
        #expect(store.log == "build log")
    }

    @Test func checkNowSaysWhenSlateIsUpToDate() async {
        updater.build = build

        await store.checkNow()

        #expect(harness.toaster.text == "Slate is up to date.")
    }
}
