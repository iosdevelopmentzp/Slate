import Foundation

package enum ActionError: LocalizedError, Hashable, Sendable {
    case timedOut

    package var errorDescription: String? {
        switch self {
        case .timedOut: "The action ran longer than 60 seconds and was stopped."
        }
    }
}
