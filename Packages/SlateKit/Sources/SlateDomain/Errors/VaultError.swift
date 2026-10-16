import Foundation

package enum VaultError: LocalizedError, Hashable, Sendable {
    case notFound(VaultPath)
    case alreadyExists(String)
    case notText(VaultPath)
    case invalidName(String)

    package var errorDescription: String? {
        switch self {
        case .notFound(let path):
            "\(path.rawValue) is not in the notes folder any more. It may have been moved or deleted."
        case .alreadyExists(let name):
            "\(name) already exists. Choose another name."
        case .notText(let path):
            "\(path.rawValue) is not a UTF-8 text file. Open it in another app."
        case .invalidName(let name):
            "\"\(name)\" cannot be a folder name. Use letters, numbers and spaces."
        }
    }
}
