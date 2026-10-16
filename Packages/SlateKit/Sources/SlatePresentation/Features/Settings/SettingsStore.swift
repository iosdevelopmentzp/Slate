import Foundation
import Observation
import SlateDomain

@MainActor
@Observable
final class SettingsStore {
    static let fontSizes = Array(12...20)
    static let retentionChoices = [7, 14, 30, 60, 90]

    var editorFontSize: Int {
        didSet { store.set(editorFontSize, forKey: Keys.fontSize) }
    }
    var appearance: AppAppearance {
        didSet { store.set(appearance.rawValue, forKey: Keys.appearance) }
    }
    var trashRetentionDays: Int {
        didSet { store.set(trashRetentionDays, forKey: Keys.retention) }
    }
    var tracker: TrackerSettings
    private(set) var loginStatus: LoginItemStatus = .disabled
    private(set) var checks: [DoctorCheck] = []
    private(set) var isChecking = false
    private(set) var isRebuilding = false
    private(set) var trackerSaved = false
    let vaultPath: String

    @ObservationIgnored var changeVault: () -> Void = {}
    @ObservationIgnored private let store: any KeyValueStore
    @ObservationIgnored private let config: any VaultConfigRepository
    @ObservationIgnored private let loginItem: any LaunchAtLogin
    @ObservationIgnored private let system: any SystemChecking
    @ObservationIgnored private let index: any SearchIndex
    @ObservationIgnored private let reindex: ReindexVaultUseCase
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let events: AppEvents

    init(
        store: any KeyValueStore,
        config: any VaultConfigRepository,
        loginItem: any LaunchAtLogin,
        system: any SystemChecking,
        index: any SearchIndex,
        reindex: ReindexVaultUseCase,
        vaultPath: String,
        activity: ActivityLog,
        events: AppEvents
    ) {
        self.store = store
        self.config = config
        self.loginItem = loginItem
        self.system = system
        self.index = index
        self.reindex = reindex
        self.vaultPath = vaultPath
        self.activity = activity
        self.events = events
        let size = store.integer(forKey: Keys.fontSize)
        editorFontSize = Self.fontSizes.contains(size) ? size : 14
        appearance = store.string(forKey: Keys.appearance).flatMap(AppAppearance.init(rawValue:)) ?? .system
        let retention = store.integer(forKey: Keys.retention)
        trashRetentionDays = retention > 0 ? retention : 30
        tracker = TrackerSettings.load(from: store)
    }

    var loginHint: String? {
        switch loginStatus {
        case .requiresApproval: "Allow Slate in System Settings → General → Login Items."
        case .unavailable: "Open Slate from the Applications folder to use this."
        case .enabled, .disabled: nil
        }
    }

    func refreshLoginStatus() async {
        loginStatus = await loginItem.status()
    }

    func setLaunchAtLogin(_ enabled: Bool) async {
        do {
            try await loginItem.setEnabled(enabled)
        } catch {
            activity.log("Cannot change Open at login", detail: error.localizedDescription, outcome: .failure)
        }
        await refreshLoginStatus()
    }

    func saveTracker() async {
        tracker.save(to: store)
        do {
            let existing = try await config.linkPatterns()
            let defaults = LinkPatternPolicy.defaults(for: tracker)
            let defaultIDs = Set(["jira", "gitlab-mr", "gitlab-issue"])
            let kept = existing.filter { defaultIDs.contains($0.id) == false }
            try await config.saveLinkPatterns(defaults + kept)
            trackerSaved = true
            events.post(.vaultRescanned)
        } catch {
            activity.log("Cannot save the link settings", detail: error.localizedDescription, outcome: .failure)
        }
    }

    func runDoctor() async {
        isChecking = true
        checks = await system.checks()
        isChecking = false
    }

    func rebuildIndex() async {
        isRebuilding = true
        defer { isRebuilding = false }
        do {
            try await index.reset()
            let report = try await reindex.execute(.all)
            events.post(.indexUpdated)
            activity.log("Rebuilt search", detail: "\(report.indexed.count) notes", outcome: .success)
        } catch {
            activity.log("Cannot rebuild search", detail: error.localizedDescription, outcome: .failure)
        }
        await runDoctor()
    }

    private enum Keys {
        static let fontSize = "editor.fontSize"
        static let appearance = "appearance"
        static let retention = "trash.retentionDays"
    }
}
