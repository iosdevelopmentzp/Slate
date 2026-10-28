import Foundation
import Observation
import SlateDomain

@MainActor
@Observable
final class FileViewerStore {
    enum Content: Equatable {
        case loading
        case text
        case preview
        case missing
    }

    private(set) var path: VaultPath?
    private(set) var meta: FileMeta?
    private(set) var content: Content = .loading
    private(set) var hasConflict = false
    private(set) var previewToken = 0
    private(set) var textToken = 0
    var text = "" {
        didSet {
            guard isApplying == false, text != oldValue else { return }
            isDirty = true
            schedule(after: .milliseconds(600))
        }
    }

    @ObservationIgnored private let files: any VaultFileStore
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let vaultRoot: URL
    @ObservationIgnored private var hash: ContentHash?
    @ObservationIgnored private var isDirty = false
    @ObservationIgnored private var isApplying = false
    @ObservationIgnored private var saveTask: Task<Void, Never>?
    @ObservationIgnored private var subscription: SubscriptionToken?

    init(files: any VaultFileStore, activity: ActivityLog, events: AppEvents, vaultRoot: URL) {
        self.files = files
        self.activity = activity
        self.vaultRoot = vaultRoot
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            handle(event)
        }
    }

    var url: URL? {
        path.map { vaultRoot.appendingPathComponent($0.rawValue, isDirectory: false) }
    }

    func open(_ path: VaultPath?) async {
        guard path != self.path else { return }
        await flush()
        self.path = path
        meta = nil
        hash = nil
        hasConflict = false
        content = .loading
        apply("")
        guard let path else { return }
        await load(path)
    }

    func flush() async {
        saveTask?.cancel()
        saveTask = nil
        await persist()
    }

    func pendingSave() -> (@Sendable () async -> Void)? {
        guard let path, isDirty, hasConflict == false, let hash else { return nil }
        let data = Data(text.utf8)
        let files = files
        return {
            _ = try? await files.write(path, data: data, expected: hash)
        }
    }

    func keepMine() async {
        guard let path else { return }
        hash = (try? await files.read(path))?.hash
        hasConflict = false
        isDirty = true
        await persist()
    }

    func takeTheirs() async {
        guard let path else { return }
        hasConflict = false
        isDirty = false
        await load(path)
    }

    private func load(_ path: VaultPath) async {
        do {
            guard let meta = try await files.meta(path) else {
                guard self.path == path else { return }
                content = .missing
                return
            }
            guard FileKindPolicy.mayBeText(path, size: meta.size) else {
                guard self.path == path else { return }
                show(meta, as: .preview)
                return
            }
            let contents = try await files.read(path)
            guard self.path == path else { return }
            guard let string = FileKindPolicy.text(from: contents.data) else {
                show(contents.meta, as: .preview)
                return
            }
            self.meta = contents.meta
            hash = contents.hash
            isDirty = false
            apply(string)
            textToken += 1
            content = .text
        } catch {
            guard self.path == path else { return }
            content = .missing
            activity.log("Cannot read the file", detail: error.localizedDescription, outcome: .failure)
        }
    }

    private func show(_ meta: FileMeta, as content: Content) {
        self.meta = meta
        previewToken += 1
        self.content = content
    }

    private func apply(_ value: String) {
        isApplying = true
        text = value
        isApplying = false
    }

    private func schedule(after delay: Duration) {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard Task.isCancelled == false, let self else { return }
            await persist()
        }
    }

    private func persist() async {
        guard let path, content == .text, isDirty, hasConflict == false else { return }
        let written = text
        do {
            switch try await files.write(path, data: Data(written.utf8), expected: hash) {
            case .written(let saved):
                hash = saved
                if text == written { isDirty = false }
                meta = try? await files.meta(path)
            case .conflict:
                hasConflict = true
            }
        } catch {
            activity.log("Cannot save the file", detail: error.localizedDescription, outcome: .failure)
        }
    }

    private func handle(_ event: AppEvent) {
        switch event {
        case .vaultChanged(let paths):
            guard let path, paths.contains(path) else { return }
            Task { await checkDisk() }
        case .vaultRescanned:
            Task { await checkDisk() }
        default:
            break
        }
    }

    private func checkDisk() async {
        guard let path else { return }
        switch content {
        case .text:
            let disk = try? await files.read(path)
            guard disk?.hash != hash else { return }
            if isDirty {
                hasConflict = true
            } else {
                await load(path)
            }
        case .preview, .missing:
            await load(path)
        case .loading:
            return
        }
    }
}
