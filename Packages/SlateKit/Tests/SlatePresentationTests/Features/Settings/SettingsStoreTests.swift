import Foundation
import SlateDomain
import SlateMocks
import SlateTestSupport
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct SettingsStoreTests {
    private let harness = StoreHarness()

    private var settings: SettingsStore {
        harness.settings
    }

    @Test func preferencesHaveDefaultsAndPersist() {
        #expect(settings.editorFontSize == 14)
        #expect(settings.appearance == .system)
        #expect(settings.trashRetentionDays == 30)

        settings.editorFontSize = 16
        settings.appearance = .dark

        #expect(harness.keyValues.integer(forKey: "editor.fontSize") == 16)
        #expect(harness.keyValues.string(forKey: "appearance") == "dark")
    }

    @Test func savingTheTrackerWritesTheLinkPatterns() async throws {
        harness.spies.config.patterns = [LinkPattern(id: "own", regex: "x", url: "https://example.com/$1", label: "$1")]
        settings.tracker.trackerBaseURL = "https://example.atlassian.net"

        await settings.saveTracker()

        #expect(harness.spies.config.patterns.map(\.id) == ["jira", "own"])
        #expect(TrackerSettings.load(from: harness.keyValues).trackerBaseURL == "https://example.atlassian.net")
        #expect(harness.posted.contains(.vaultRescanned))
    }

    @Test func loginItemAsksForApprovalWithAHint() async {
        harness.spies.loginItem.current = .requiresApproval

        await settings.refreshLoginStatus()

        #expect(settings.loginHint == "Allow Slate in System Settings → General → Login Items.")
        await settings.setLaunchAtLogin(false)
        #expect(harness.spies.loginItem.calls == [false])
        #expect(settings.loginStatus == .disabled)
    }

    @Test func doctorAndRebuild() async throws {
        harness.seed("Notes/A.md", id: "a", title: "A")

        await settings.rebuildIndex()

        #expect(harness.spies.index.calls.contains(.reset))
        #expect(harness.spies.index.indexed.count == 1)
        #expect(settings.checks.map(\.id) == ["vault"])
        #expect(harness.posted.contains(.indexUpdated))
    }
}
