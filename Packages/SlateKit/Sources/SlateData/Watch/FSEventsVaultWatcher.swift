import CoreServices
import Foundation
import SlateDomain

struct FSEventsVaultWatcher: VaultWatching {
    let root: URL
    let ownWrites: OwnWrites

    func changes() -> AsyncStream<VaultChange> {
        let (stream, continuation) = AsyncStream.makeStream(of: VaultChange.self, bufferingPolicy: .bufferingNewest(32))
        let session = WatchSession(root: root, ownWrites: ownWrites) { continuation.yield($0) }
        session.start()
        continuation.onTermination = { _ in session.stop() }
        return stream
    }
}

private final class WatchSession: @unchecked Sendable {
    private let root: URL
    private let coalescer: ChangeCoalescer
    private var stream: FSEventStreamRef?

    init(root: URL, ownWrites: OwnWrites, emit: @escaping @Sendable (VaultChange) -> Void) {
        self.root = root
        coalescer = ChangeCoalescer(root: root, ownWrites: ownWrites, emit: emit)
    }

    func start() {
        var context = FSEventStreamContext(version: 0, info: Unmanaged.passUnretained(self).toOpaque(), retain: nil, release: nil, copyDescription: nil)
        let flags = UInt32(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagNoDefer | kFSEventStreamCreateFlagWatchRoot)
        guard let created = FSEventStreamCreate(kCFAllocatorDefault, Self.callback, &context, [root.path] as CFArray, FSEventStreamEventId(kFSEventStreamEventIdSinceNow), 0.3, flags) else { return }
        FSEventStreamSetDispatchQueue(created, coalescer.queue)
        FSEventStreamStart(created)
        stream = created
    }

    func stop() {
        coalescer.queue.async { [self] in
            guard let stream else { return }
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            self.stream = nil
        }
    }

    private static let callback: FSEventStreamCallback = { _, info, count, paths, flags, _ in
        guard let info else { return }
        let session = Unmanaged<WatchSession>.fromOpaque(info).takeUnretainedValue()
        let list = unsafeBitCast(paths, to: NSArray.self) as? [String] ?? []
        let rescanFlags = UInt32(kFSEventStreamEventFlagMustScanSubDirs | kFSEventStreamEventFlagRootChanged | kFSEventStreamEventFlagUserDropped | kFSEventStreamEventFlagKernelDropped)
        let events = (0..<min(count, list.count)).map { index in
            ChangeCoalescer.Event(
                path: list[index],
                isDirectory: flags[index] & UInt32(kFSEventStreamEventFlagItemIsDir) != 0,
                needsRescan: flags[index] & rescanFlags != 0
            )
        }
        session.coalescer.receive(events)
    }
}
