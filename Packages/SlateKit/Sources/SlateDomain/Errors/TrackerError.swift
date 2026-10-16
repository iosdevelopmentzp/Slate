import Foundation

package enum TrackerError: LocalizedError, Hashable, Sendable {
    case notConfigured
    case rejected(Int)
    case unreadable

    package var errorDescription: String? {
        switch self {
        case .notConfigured: "Set the tracker address, your email and a token in Settings → Links."
        case .rejected(let code): "The tracker answered with code \(code). Check the email and the token."
        case .unreadable: "The tracker sent an answer Slate cannot read."
        }
    }
}
