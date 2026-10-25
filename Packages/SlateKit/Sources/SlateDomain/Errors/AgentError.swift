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
    case badArguments(String, unknown: [String], missing: [String], wrongType: [String], accepted: [String], required: [String])
    case notAnImage
    case imageTooLarge
    case unknownTool(String)
    case serverOutdated
    case noProject(String, known: [String])
    case noTask(String)
    case notAFile(String)
    case fileTooLarge
    case textNotFound
    case textNotUnique(Int)
    case noSection(String, headings: [String])
    case noPlanItem(String, steps: [String])
    case planItemNotUnique(String, count: Int)
    case notInBatch(String)
    case batchTooLarge
    case batchStep(Int, String)
    case batchConflict(String, written: [String])

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
        case .badArguments(let tool, let unknown, let missing, let wrongType, let accepted, let required):
            Self.argumentProblems(tool, unknown: unknown, missing: missing, wrongType: wrongType, accepted: accepted, required: required)
        case .notAnImage:
            "attach_image takes PNG, JPEG, GIF, HEIC or WebP images only."
        case .imageTooLarge:
            "The image is larger than 50 MB. Make it smaller and try again."
        case .unknownTool(let name):
            "Slate has no tool \(name). Ask for the list of tools again."
        case .serverOutdated:
            "Slate was updated after this session started, and this slate mcp server still runs the old version. Nothing was changed. Ask the owner to reconnect the slate server: in Claude Code, /mcp, slate, Reconnect. Then call the tool again."
        case .noProject(let place, let known):
            "No Slate project belongs to \(place). Projects: \(known.isEmpty ? "none" : known.joined(separator: ", ")). Pass project with one of these names, or ask the owner to link the repository: right click the project in Slate, Link Repository…, or run slate project add <Name> --repo <path>."
        case .noTask(let task):
            "No task matches \(task). Use project_context to see the tasks, or start one with start_task."
        case .notAFile(let path):
            "\(path) is not a file on this Mac. Pass an absolute path or base64 with a name."
        case .fileTooLarge:
            "The file is larger than 200 MB. Keep a link to it in a note instead."
        case .textNotFound:
            "The note does not have this text. Read the note or the section again and copy the text exactly."
        case .textNotUnique(let count):
            "The note has this text \(count) times. Add more of the text around it, so that it matches one place."
        case .noSection(let heading, let headings):
            "The note has no section \(heading). Sections: \(headings.isEmpty ? "none" : headings.joined(separator: ", "))."
        case .noPlanItem(let item, let steps) where steps.isEmpty:
            "The Plan has no checklist steps, so nothing matches \(item). Add steps with append_to_note, section Plan, text - [ ] 1. The step."
        case .noPlanItem(let item, let steps):
            "No step of the Plan matches \(item). Steps: \(steps.joined(separator: "; "))."
        case .planItemNotUnique(let item, let count):
            "\(count) steps of the Plan match \(item). Pass the step number instead."
        case .notInBatch(let tool):
            "batch_edit takes replace_in_note, update_section, append_to_note and set_plan_item, not \(tool)."
        case .batchTooLarge:
            "batch_edit takes at most 50 operations. Split them into more calls."
        case .batchStep(let step, let reason):
            "Operation \(step): \(reason) Nothing was written."
        case .batchConflict(let path, let written):
            "\(path) changed while the batch was written, so it was not changed. \(written.isEmpty ? "Nothing was written." : "Already written: \(written.joined(separator: ", ")).") Read the note again and repeat the rest."
        }
    }

    private static func argumentProblems(_ tool: String, unknown: [String], missing: [String], wrongType: [String], accepted: [String], required: [String]) -> String {
        var parts: [String] = []
        if unknown.isEmpty == false {
            parts.append("\(tool) has no argument\(unknown.count == 1 ? "" : "s") \(unknown.joined(separator: ", ")).")
        }
        if missing.isEmpty == false {
            parts.append("Missing: \(missing.joined(separator: ", ")).")
        }
        if wrongType.isEmpty == false {
            parts.append("Wrong type: \(wrongType.joined(separator: ", ")).")
        }
        parts.append("\(tool) takes \(accepted.isEmpty ? "no arguments" : accepted.joined(separator: ", "))\(required.isEmpty ? "" : "; required: \(required.joined(separator: ", "))").")
        parts.append("Nothing was changed. Call it again with these names.")
        return parts.joined(separator: " ")
    }
}
