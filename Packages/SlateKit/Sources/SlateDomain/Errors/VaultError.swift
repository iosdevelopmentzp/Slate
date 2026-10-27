import Foundation

package enum VaultError: LocalizedError, Hashable, Sendable {
    case notFound(VaultPath)
    case alreadyExists(String)
    case notText(VaultPath)
    case invalidName(String)
    case defaultFolder(String)
    case defaultFolderMove(String)
    case projectMove(String)

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
        case .defaultFolder(let name):
            "\(name) keeps new and quick notes, so it cannot be deleted. Choose another folder for quick notes first."
        case .defaultFolderMove(let name):
            "\(name) keeps new and quick notes, so it stays at the top level. Choose another folder for quick notes first."
        case .projectMove(let name):
            "\(name) is a project, so it stays at the top level. Make it a folder first to move it."
        }
    }
}
