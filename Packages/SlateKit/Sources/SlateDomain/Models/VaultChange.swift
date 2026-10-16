import Foundation

package enum VaultChange: Hashable, Sendable {
    case paths(Set<VaultPath>)
    case rescan
}
