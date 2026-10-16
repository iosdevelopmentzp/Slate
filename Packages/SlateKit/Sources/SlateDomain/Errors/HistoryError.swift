import Foundation

package enum HistoryError: LocalizedError, Hashable, Sendable {
    case gitMissing
    case command(String)

    package var errorDescription: String? {
        switch self {
        case .gitMissing:
            "Git is not installed, so Slate keeps no versions. Run xcode-select --install in Terminal."
        case .command(let message):
            message
        }
    }
}
