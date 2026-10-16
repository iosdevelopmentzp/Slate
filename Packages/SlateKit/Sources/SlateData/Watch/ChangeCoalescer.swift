import Foundation
import SlateDomain

final class ChangeCoalescer: @unchecked Sendable {
    struct Event: Sendable {
        let path: String
        let isDirectory: Bool
        let needsRescan: Bool
    }

    static let ignoredNames: Set<String> = [".DS_Store", ".git", ".obsidian", ".trash"]

    let queue = DispatchQueue(label: "Slate.ChangeCoalescer")

    private let root: URL
    private let ownWrites: OwnWrites
    private let delay: TimeInterval
    private let emit: @Sendable (VaultChange) -> Void
    private var pending: Set<VaultPath> = []
    private var needsRescan = false
    private var isScheduled = false

    init(root: URL, ownWrites: OwnWrites, delay: TimeInterval = 0.3, emit: @escaping @Sendable (VaultChange) -> Void) {
        self.root = root
        self.ownWrites = ownWrites
        self.delay = delay
        self.emit = emit
    }

    func receive(_ events: [Event]) {
        record(events)
        guard isScheduled == false else { return }
        isScheduled = true
        queue.asyncAfter(deadline: .now() + delay) { [self] in
            isScheduled = false
            flush()
        }
    }

    func record(_ events: [Event]) {
        for event in events {
            switch Self.classify(event, root: root) {
            case .ignore:
                continue
            case .rescan:
                needsRescan = true
            case .note(let path):
                pending.insert(path)
            }
        }
    }

    func flush() {
        defer {
            pending = []
            needsRescan = false
        }
        if needsRescan {
            emit(.rescan)
            return
        }
        let external = pending.filter { path in
            let disk = (try? Data(contentsOf: root.appendingPathComponent(path.rawValue))).map(ContentHash.of)
            return ownWrites.isOwn(path, diskHash: disk) == false
        }
        guard external.isEmpty == false else { return }
        emit(.paths(external))
    }

    enum Classification: Hashable {
        case ignore
        case rescan
        case note(VaultPath)
    }

    static func classify(_ event: Event, root: URL) -> Classification {
        if event.needsRescan { return .rescan }
        guard let relative = relativePath(event.path, root: root), relative.isEmpty == false else { return .ignore }
        let components = relative.split(separator: "/").map(String.init)
        guard let first = components.first, let name = components.last else { return .rescan }
        if components.contains(where: ignoredNames.contains) || name.hasSuffix(".slate-tmp") || name.hasSuffix(".slate-rename") {
            return .ignore
        }
        if first == ".slate" || first == "_templates" { return .rescan }
        if first.hasPrefix(".") || first.hasPrefix("_") { return .ignore }
        if components.count == 1 || event.isDirectory { return .rescan }
        let path = VaultPath(rawValue: relative)
        return path.isNote ? .note(path) : .ignore
    }

    static func relativePath(_ eventPath: String, root: URL) -> String? {
        let base = normalized(root.resolvingSymlinksInPath().path)
        let path = normalized(eventPath)
        if path.lowercased() == base.lowercased() { return "" }
        let prefix = base.hasSuffix("/") ? base : base + "/"
        guard path.lowercased().hasPrefix(prefix.lowercased()) else { return nil }
        return String(path.dropFirst(prefix.count))
    }

    private static let privatePrefixes = ["/private/var/", "/private/tmp/", "/private/etc/"]

    private static func normalized(_ path: String) -> String {
        let standard = URL(fileURLWithPath: path).standardizedFileURL.path
        guard privatePrefixes.contains(where: standard.hasPrefix) else { return standard }
        return String(standard.dropFirst("/private".count))
    }
}
