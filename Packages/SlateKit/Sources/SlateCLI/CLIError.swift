import Foundation

enum CLIError: LocalizedError {
    case noVault
    case notFound(String)
    case nothingToDo(String)

    var errorDescription: String? {
        switch self {
        case .noVault:
            "No notes folder. Open Slate once, or pass --vault <folder> or set SLATE_VAULT."
        case .notFound(let what):
            "No note matches \(what)."
        case .nothingToDo(let hint):
            hint
        }
    }
}
