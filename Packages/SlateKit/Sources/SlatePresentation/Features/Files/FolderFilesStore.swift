import Foundation
import Observation
import SlateDomain

@MainActor
@Observable
final class FolderFilesStore {
    private(set) var folder: FolderPath?
    private(set) var files: [FileMeta] = []
    private(set) var renaming: VaultPath?
    var draftName = ""

    @ObservationIgnored private let store: any VaultFileStore
    @ObservationIgnored private let workspace: any WorkspaceOpening
    @ObservationIgnored private let exporter: any NoteExporting
    @ObservationIgnored private let toaster: Toaster
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let events: AppEvents
    @ObservationIgnored private let vaultRoot: URL
    @ObservationIgnored private let refreshTask = RefreshTask()
    @ObservationIgnored private var subscription: SubscriptionToken?

    init(files: any VaultFileStore, workspace: any WorkspaceOpening, exporter: any NoteExporting, toaster: Toaster, activity: ActivityLog, events: AppEvents, vaultRoot: URL) {
        store = files
        self.workspace = workspace
        self.exporter = exporter
        self.toaster = toaster
        self.activity = activity
        self.events = events
        self.vaultRoot = vaultRoot
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            handle(event)
        }
    }

    func show(_ folder: FolderPath?) async {
        guard folder != self.folder else { return }
        self.folder = folder
        renaming = nil
        files = []
        await refresh()
    }

    func refresh() async {
        await refreshTask.run { [weak self] in
            guard let self else { return }
            guard let folder else {
                if files.isEmpty == false { files = [] }
                return
            }
            do {
                let loaded = try await store.files(in: folder)
                if loaded != files { files = loaded }
            } catch {
                activity.log("Cannot read the files", detail: error.localizedDescription, outcome: .failure)
            }
        }
    }

    func url(for path: VaultPath) -> URL {
        vaultRoot.appendingPathComponent(path.rawValue, isDirectory: false)
    }

    func quickLook(_ path: VaultPath) async {
        await workspace.quickLook(url(for: path))
    }

    func open(_ path: VaultPath) async {
        await workspace.open(url(for: path))
    }

    func reveal(_ path: VaultPath) async {
        await workspace.reveal(url(for: path))
    }

    func copyPath(_ path: VaultPath) {
        toaster.copy(url(for: path).path, label: "Path")
    }

    func saveToDownloads(_ path: VaultPath) async {
        do {
            let saved = try await exporter.copyToDownloads(url(for: path))
            toaster.show("Saved \(saved.lastPathComponent) to Downloads")
        } catch {
            report("Cannot save the file to Downloads", error)
        }
    }

    func dragProvider(for path: VaultPath) -> NSItemProvider {
        NSItemProvider(contentsOf: url(for: path)) ?? NSItemProvider()
    }

    @discardableResult
    func importFiles(_ urls: [URL]) async -> [VaultPath] {
        guard let folder, urls.isEmpty == false else { return [] }
        var added: [VaultPath] = []
        for url in urls where url.pathExtension.lowercased() != VaultPath.noteExtension {
            do {
                added.append(try await store.importFile(url, into: folder))
            } catch {
                report("Cannot add \(url.lastPathComponent)", error)
            }
        }
        guard added.isEmpty == false else { return [] }
        await refresh()
        toaster.show(added.count == 1 ? "Added \(added[0].fileName)" : "Added \(added.count) files")
        return added
    }

    func startRename(_ path: VaultPath) {
        renaming = path
        draftName = path.fileName
    }

    func cancelRename() {
        renaming = nil
        draftName = ""
    }

    @discardableResult
    func commitRename() async -> Bool {
        guard let path = renaming else { return false }
        guard let name = FileNamePolicy.renamed(draftName, keeping: path.fileName) else {
            toaster.show("A file name cannot be empty or start with a dot.")
            return false
        }
        cancelRename()
        guard name != path.fileName else { return true }
        let target = VaultPath(rawValue: path.folder.isEmpty ? name : "\(path.folder)/\(name)")
        do {
            try await store.move(from: path, to: target)
            await refresh()
            return true
        } catch {
            report("Cannot rename the file", error)
            return false
        }
    }

    func trash(_ path: VaultPath) async {
        do {
            let trashed = try await store.trashFile(path)
            await refresh()
            toaster.show("Moved \(path.fileName) to the Trash", action: ToastAction(title: "Undo") { [weak self] in
                guard let self else { return }
                Task { await self.restore(trashed, to: path) }
            })
        } catch {
            report("Cannot move the file to the Trash", error)
        }
    }

    func restore(_ trashed: URL, to path: VaultPath) async {
        do {
            try await store.restoreFile(trashed, to: path)
            await refresh()
            toaster.show("\(path.fileName) is back")
        } catch {
            report("Cannot bring the file back", error)
        }
    }

    private func handle(_ event: AppEvent) {
        switch event {
        case .vaultRescanned:
            Task { await refresh() }
        case .vaultChanged(let paths):
            guard let folder, paths.contains(where: { $0.folder == folder.rawValue }) else { return }
            Task { await refresh() }
        default:
            return
        }
    }

    private func report(_ title: String, _ error: any Error) {
        activity.log(title, detail: error.localizedDescription, outcome: .failure)
        toaster.show(error.localizedDescription)
    }
}
