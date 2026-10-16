import Foundation
import SlateDomain

package final class SpyVaultWatcher: VaultWatching, @unchecked Sendable {
    private let lock = NSLock()
    private var continuations: [AsyncStream<VaultChange>.Continuation] = []

    package init() {}

    package var subscriberCount: Int {
        lock.withLock { continuations.count }
    }

    package func changes() -> AsyncStream<VaultChange> {
        let (stream, continuation) = AsyncStream.makeStream(of: VaultChange.self)
        lock.withLock { continuations.append(continuation) }
        return stream
    }

    package func send(_ change: VaultChange) {
        lock.withLock { continuations }.forEach { $0.yield(change) }
    }
}
