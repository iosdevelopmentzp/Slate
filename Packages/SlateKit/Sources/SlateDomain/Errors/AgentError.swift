import Foundation

package enum AgentError: LocalizedError, Hashable, Sendable {
    case folderNotAllowed(String, allowed: [String])
    case createNotAllowed
    case trashNotAllowed
    case outsideNotes(String)
    case badFolder(String)
    case noFolder(String)
    case noteNotFound(String)
    case staleNote
    case missingArgument(String)
    case notAnImage
    case imageTooLarge
    case unknownTool(String)
    case noProject(String, known: [String])
    case noTask(String)
    case notAFile(String)
    case fileTooLarge

    private static let settingsHint = "The owner can change this in Slate: Settings → General → AI access."

    package var errorDescription: String? {
        switch self {
        case .folderNotAllowed(let folder, let allowed):
            "Agents may not change notes in \(folder). Allowed: \(allowed.isEmpty ? "none" : allowed.joined(separator: ", ")). \(Self.settingsHint)"
        case .createNotAllowed:
            "Agents may not create notes. \(Self.settingsHint)"
        case .trashNotAllowed:
            "Agents may not move notes to the Trash. \(Self.settingsHint)"
        case .outsideNotes(let path):
            "\(path) is not a note in the notes folder. Use a path like Notes/Plan.md, or an id from list_notes."
        case .badFolder(let folder):
            "\(folder) cannot be a folder for notes. Use a name from list_folders, like Notes or Work/Clients."
        case .noFolder(let folder):
            "There is no folder \(folder). Use a name from list_folders."
        case .noteNotFound(let id):
            "No note has the id \(id). Use list_notes or search_notes to find the id."
        case .staleNote:
            "The note changed since you read it, read it again."
        case .missingArgument(let name):
            "Pass \(name)."
        case .notAnImage:
            "attach_image takes PNG, JPEG, GIF, HEIC or WebP images only."
        case .imageTooLarge:
            "The image is larger than 50 MB. Make it smaller and try again."
        case .unknownTool(let name):
            "Slate has no tool \(name). Ask for the list of tools again."
        case .noProject(let place, let known):
            "No Slate project belongs to \(place). Projects: \(known.isEmpty ? "none" : known.joined(separator: ", ")). Pass project with one of these names, or ask the owner to link the repository: right click the project in Slate, Link Repository…, or run slate project add <Name> --repo <path>."
        case .noTask(let task):
            "No task matches \(task). Use project_context to see the tasks, or start one with start_task."
        case .notAFile(let path):
            "\(path) is not a file on this Mac. Pass an absolute path or base64 with a name."
        case .fileTooLarge:
            "The file is larger than 200 MB. Keep a link to it in a note instead."
        }
    }
}
