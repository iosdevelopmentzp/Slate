import Foundation
import SlateDomain

struct MockVaultWatcher: VaultWatching {
    func changes() -> AsyncStream<VaultChange> {
        AsyncStream { _ in }
    }
}
