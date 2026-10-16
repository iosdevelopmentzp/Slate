import Foundation

package enum ReindexScope: Hashable, Sendable {
    case all
    case paths(Set<VaultPath>)
}
