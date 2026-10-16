import Foundation

package protocol VaultWatching: Sendable {
    func changes() -> AsyncStream<VaultChange>
}
