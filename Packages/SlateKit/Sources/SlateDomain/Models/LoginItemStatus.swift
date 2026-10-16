import Foundation

package enum LoginItemStatus: Hashable, Sendable {
    case enabled
    case disabled
    case requiresApproval
    case unavailable
}
