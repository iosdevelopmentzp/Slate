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
        #expect(settings.editorFontSize == 15)
        #expect(settings.appearance == .system)
        #expect(settings.trashRetentionDays == 30)

        settings.editorFontSize = 16
        settings.appearance = .dark

        #expect(harness.keyValues.integer(forKey: "editor.fontSize") == 16)
        #expect(harness.keyValues.string(forKey: "appearance") == "dark")
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
        #expect(settings.checks.map(\.id) == ["vault", "notes", "snapshot"])
        #expect(settings.checks.first { $0.id == "notes" }?.detail == "1 note")
        #expect(harness.posted.contains(.indexUpdated))
    }
}
