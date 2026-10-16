import Foundation

package enum WriteResult: Hashable, Sendable {
    case written(ContentHash)
    case conflict(diskHash: ContentHash?)
}
