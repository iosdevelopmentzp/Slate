import Foundation
import Observation
import SlateDomain

@MainActor
@Observable
final class VersionsStore {
    static let changeLimit = 100

    private(set) var preview: VersionPreview?
    private(set) var fileVersions: [Snapshot] = []
    private(set) var changes: [SnapshotChange] = []
    private(set) var isLoading = false
    private(set) var confirmingClear: ClearTarget?
    private(set) var isClearing = false

    @ObservationIgnored private let history: any HistoryRepository
    @ObservationIgnored private let files: any VaultFileStore
    @ObservationIgnored private let snapshot: SnapshotHistoryUseCase
    @ObservationIgnored private let restoreFileVersion: RestoreFileVersionUseCase
    @ObservationIgnored private let clearHistory: ClearHistoryUseCase
    @ObservationIgnored private let exporter: any NoteExporting
    @ObservationIgnored private let workspace: any WorkspaceOpening
    @ObservationIgnored private let toaster: Toaster
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let events: AppEvents

    init(
        history: any HistoryRepository,
        files: any VaultFileStore,
        snapshot: SnapshotHistoryUseCase,
        restoreFileVersion: RestoreFileVersionUseCase,
        clearHistory: ClearHistoryUseCase,
        exporter: any NoteExporting,
        workspace: any WorkspaceOpening,
        toaster: Toaster,
        activity: ActivityLog,
        events: AppEvents
    ) {
        self.history = history
        self.files = files
        self.snapshot = snapshot
        self.restoreFileVersion = restoreFileVersion
        self.clearHistory = clearHistory
        self.exporter = exporter
        self.workspace = workspace
        self.toaster = toaster
        self.activity = activity
        self.events = events
    }

    func select(_ version: Snapshot, of path: VaultPath) async {
        do {
            let old = try await history.contents(of: path, at: version.hash)
            let current = try await files.read(path)
            let oldText = Self.body(of: old, meta: current.meta)
            let currentText = Self.body(of: current.data, meta: current.meta)
            let diff = LineDiffPolicy.lines(from: oldText, to: currentText)
            let counts = LineDiffPolicy.counts(diff)
            preview = VersionPreview(snapshot: version, text: oldText, diff: diff, added: counts.added, removed: counts.removed)
        } catch {
            preview = nil
            report("Cannot read the version", error)
        }
    }

    func clearPreview() {
        preview = nil
    }

    @discardableResult
    func saveVersion(_ name: String) async -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\n", with: " ")
        guard trimmed.isEmpty == false else { return false }
        do {
            let outcome = try await snapshot.execute(push: false, message: Snapshot.versionPrefix + trimmed)
            toaster.show(outcome.committed ? "Saved the version \u{201C}\(trimmed)\u{201D}" : "Nothing changed since the last version")
            if outcome.committed { events.post(.indexUpdated) }
            return outcome.committed
        } catch {
            report("Cannot save the version", error)
            return false
        }
    }

    func loadFileVersions(_ path: VaultPath) async {
        isLoading = true
        defer { isLoading = false }
        fileVersions = (try? await history.history(of: path)) ?? []
    }

    func quickLook(_ version: Snapshot, of path: VaultPath) async {
        do {
            let data = try await history.contents(of: path, at: version.hash)
            let url = try await exporter.temporaryFile(data, fileName: Self.versionName(of: path, at: version.date))
            await workspace.quickLook(url)
        } catch {
            report("Cannot show the version", error)
        }
    }

    func restoreFile(_ version: Snapshot, of path: VaultPath) async {
        do {
            try await restoreFileVersion.execute(version, of: path)
            events.post(.vaultChanged([path]))
            toaster.show("Restored the earlier \(path.fileName)")
            await loadFileVersions(path)
        } catch {
            report("Cannot restore the version", error)
        }
    }

    func loadChanges(in folder: FolderPath?) async {
        isLoading = true
        defer { isLoading = false }
        do {
            changes = try await history.changes(in: folder, limit: Self.changeLimit)
        } catch {
            changes = []
            report("Cannot read the changes", error)
        }
    }

    func requestClear(_ target: ClearTarget) {
        confirmingClear = target
    }

    func cancelClear() {
        confirmingClear = nil
    }

    func confirmClear() async {
        guard let target = confirmingClear, isClearing == false else { return }
        confirmingClear = nil
        isClearing = true
        defer { isClearing = false }
        do {
            try await clearHistory.execute(target.folder)
            changes = []
            preview = nil
            fileVersions = []
            if let folder = target.folder {
                await loadChanges(in: folder)
                toaster.show("Cleared the history of \(folder.name)")
            } else {
                toaster.show("Cleared the history. Slate keeps the notes as they are now.")
            }
            activity.log(target.folder.map { "Cleared the history of \($0.rawValue)" } ?? "Cleared the history", detail: "Only the notes as they are now are kept as a version.", outcome: .success)
        } catch {
            report("Cannot clear the history", error)
        }
    }

    static func versionName(of path: VaultPath, at date: Date) -> String {
        let ext = (path.fileName as NSString).pathExtension
        let base = (path.fileName as NSString).deletingPathExtension
        let stamp = date.formatted(.iso8601.year().month().day().time(includingFractionalSeconds: false)).replacingOccurrences(of: ":", with: ".")
        return ext.isEmpty ? "\(base) \(stamp)" : "\(base) \(stamp).\(ext)"
    }

    private static func body(of data: Data, meta: FileMeta) -> String {
        guard meta.path.isNote, let document = try? NoteCodec.decode(FileContents(data: data, hash: .of(data), meta: meta)) else {
            return String(decoding: data, as: UTF8.self)
        }
        return document.body
    }

    private func report(_ title: String, _ error: any Error) {
        activity.log(title, detail: error.localizedDescription, outcome: .failure)
        toaster.show(error.localizedDescription)
    }
}
