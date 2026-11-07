import Foundation

package enum UpdateError: LocalizedError, Hashable, Sendable {
    case fetchFailed(String)
    case noScript(String)
    case startFailed(String)

    package var errorDescription: String? {
        switch self {
        case .fetchFailed(let detail):
            "Slate could not get the changes from git. \(detail)"
        case .noScript(let path):
            "The update script is missing at \(path). Run Scripts/install.sh again."
        case .startFailed(let detail):
            "The update did not start. \(detail)"
        }
    }
}
