import Foundation
import SlateDomain

struct FileVaultConfigRepository: VaultConfigRepository {
    static let folderName = ".slate"

    let root: URL

    private var configFolder: URL {
        root.appendingPathComponent(Self.folderName, isDirectory: true)
    }

    private var spacesURL: URL {
        configFolder.appendingPathComponent("spaces.json")
    }

    private var linksURL: URL {
        configFolder.appendingPathComponent("links.json")
    }

    private var viewsURL: URL {
        configFolder.appendingPathComponent("views.json")
    }

    private var actionsFolder: URL {
        configFolder.appendingPathComponent("actions", isDirectory: true)
    }

    private var typesFolder: URL {
        configFolder.appendingPathComponent("types", isDirectory: true)
    }

    func spaces() async throws -> SpacesConfig {
        let folders = try VaultFolder(root: root).spaceFolders()
        let stored = try JSONFile.object(at: spacesURL)
        let entries = (stored?["spaces"] as? [[String: Any]] ?? []).compactMap(Self.space)
        let configured = entries.isEmpty && stored == nil ? SpacesConfig.defaults.spaces : entries
        let present = Set(folders)
        var spaces = configured.filter { present.contains($0.folder) }
        let listed = Set(spaces.map(\.folder))
        spaces += folders.filter { listed.contains($0) == false }.map { Space(folder: $0, icon: "folder", defaultType: NoteType.defaultName) }
        return SpacesConfig(
            spaces: spaces,
            captureSpace: (stored?["captureSpace"] as? String).map(SpaceName.init(rawValue:)) ?? SpacesConfig.defaultCaptureSpace,
            archiveSpace: (stored?["archiveSpace"] as? String).map(SpaceName.init(rawValue:)) ?? SpacesConfig.defaultArchiveSpace,
            dailySpace: (stored?["dailySpace"] as? String).map(SpaceName.init(rawValue:)) ?? SpacesConfig.defaultDailySpace
        )
    }

    func saveSpaces(_ config: SpacesConfig) async throws {
        var object = try JSONFile.object(at: spacesURL) ?? [:]
        let previous = (object["spaces"] as? [[String: Any]] ?? []).reduce(into: [String: [String: Any]]()) { result, entry in
            if let folder = entry["folder"] as? String {
                result[folder] = entry
            }
        }
        object["version"] = 1
        object["spaces"] = config.spaces.map { space -> [String: Any] in
            var entry = previous[space.folder.rawValue] ?? [:]
            entry["folder"] = space.folder.rawValue
            entry["icon"] = space.icon ?? "folder"
            entry["defaultType"] = space.defaultType ?? NoteType.defaultName
            return entry
        }
        object["captureSpace"] = config.captureSpace.rawValue
        object["archiveSpace"] = config.archiveSpace.rawValue
        object["dailySpace"] = config.dailySpace.rawValue
        try JSONFile.write(object, to: spacesURL)
    }

    func types() async throws -> [NoteType] {
        var types = NoteType.builtIn
        guard FileManager.default.fileExists(atPath: typesFolder.path) else { return types }
        let files = try FileManager.default.contentsOfDirectory(at: typesFolder, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        for file in files {
            guard let object = try? JSONFile.object(at: file), let type = Self.type(from: object) else { continue }
            if let index = types.firstIndex(where: { $0.name == type.name }) {
                types[index] = type
            } else {
                types.append(type)
            }
        }
        return types
    }

    func ensureDefaults() async throws {
        if FileManager.default.fileExists(atPath: spacesURL.path) == false {
            try await saveSpaces(try await spaces())
        }
        if FileManager.default.fileExists(atPath: viewsURL.path) == false {
            try JSONFile.write(["version": 1, "views": SmartView.defaults.map(Self.object)], to: viewsURL)
        }
        if FileManager.default.fileExists(atPath: actionsFolder.path) == false {
            for (name, action) in Self.exampleActions {
                try JSONFile.write(Self.object(for: action), to: actionsFolder.appendingPathComponent("\(name).json"))
            }
        }
        for type in NoteType.builtIn {
            let url = typesFolder.appendingPathComponent("\(type.name).json")
            guard FileManager.default.fileExists(atPath: url.path) == false else { continue }
            try JSONFile.write(Self.object(for: type), to: url)
        }
    }

    func linkPatterns() async throws -> [LinkPattern] {
        guard let object = try JSONFile.object(at: linksURL) else { return [] }
        return (object["patterns"] as? [[String: Any]] ?? []).compactMap(Self.pattern)
    }

    func saveLinkPatterns(_ patterns: [LinkPattern]) async throws {
        var object = try JSONFile.object(at: linksURL) ?? [:]
        let previous = (object["patterns"] as? [[String: Any]] ?? []).reduce(into: [String: [String: Any]]()) { result, entry in
            if let id = entry["id"] as? String { result[id] = entry }
        }
        object["version"] = 1
        object["patterns"] = patterns.map { pattern -> [String: Any] in
            var entry = previous[pattern.id] ?? [:]
            entry["id"] = pattern.id
            entry["regex"] = pattern.regex
            entry["url"] = pattern.url
            entry["label"] = pattern.label
            entry["icon"] = pattern.icon
            return entry
        }
        try JSONFile.write(object, to: linksURL)
    }

    func views() async throws -> [SmartView] {
        guard let object = try JSONFile.object(at: viewsURL) else { return SmartView.defaults }
        return (object["views"] as? [[String: Any]] ?? []).compactMap { entry in
            guard let id = entry["id"] as? String, let title = entry["title"] as? String, let query = entry["query"] as? String else { return nil }
            return SmartView(id: id, title: title, icon: entry["icon"] as? String ?? "magnifyingglass", query: query)
        }
    }

    func actions() async throws -> [ActionDefinition] {
        guard FileManager.default.fileExists(atPath: actionsFolder.path) else { return [] }
        let files = try FileManager.default.contentsOfDirectory(at: actionsFolder, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        return files.compactMap { file in
            guard let object = try? JSONFile.object(at: file), let title = object["title"] as? String, let command = object["command"] as? String else { return nil }
            return ActionDefinition(
                id: file.deletingPathExtension().lastPathComponent,
                title: title,
                icon: object["icon"] as? String,
                command: command,
                condition: (object["when"] as? String).flatMap(ActionDefinition.Condition.init(rawValue:)) ?? .always,
                output: (object["output"] as? String).flatMap(ActionDefinition.Output.init(rawValue:)) ?? .activity
            )
        }
    }

    static let exampleActions: [(String, ActionDefinition)] = [
        ("open-folder-in-terminal", ActionDefinition(id: "open-folder-in-terminal", title: "Open the note's folder in Terminal", icon: "terminal", command: "open -a Terminal \"$(dirname \"$SLATE_NOTE_PATH\")\"")),
        ("copy-branch", ActionDefinition(id: "copy-branch", title: "Copy the branch name", icon: "arrow.branch", command: "printf %s \"$SLATE_BRANCH\"", condition: .hasBranch, output: .clipboard)),
        ("list-folder", ActionDefinition(id: "list-folder", title: "Add the list of files in the note's folder", icon: "list.bullet", command: "ls -1 \"$(dirname \"$SLATE_NOTE_PATH\")\"", output: .appendToNote)),
    ]

    private static func object(for view: SmartView) -> [String: Any] {
        ["id": view.id, "title": view.title, "icon": view.icon, "query": view.query]
    }

    private static func object(for action: ActionDefinition) -> [String: Any] {
        var object: [String: Any] = ["version": 1, "title": action.title, "command": action.command, "when": action.condition.rawValue, "output": action.output.rawValue]
        object["icon"] = action.icon
        return object
    }

    private static func pattern(from entry: [String: Any]) -> LinkPattern? {
        guard let id = entry["id"] as? String, let regex = entry["regex"] as? String, let url = entry["url"] as? String else { return nil }
        return LinkPattern(id: id, regex: regex, url: url, label: entry["label"] as? String ?? "$0", icon: entry["icon"] as? String)
    }

    private static func space(from entry: [String: Any]) -> Space? {
        guard let folder = entry["folder"] as? String, folder.isEmpty == false else { return nil }
        return Space(folder: SpaceName(rawValue: folder), icon: entry["icon"] as? String, defaultType: entry["defaultType"] as? String)
    }

    private static func type(from object: [String: Any]) -> NoteType? {
        guard let name = object["type"] as? String, name.isEmpty == false else { return nil }
        return NoteType(
            name: name,
            title: object["title"] as? String ?? name.capitalized,
            icon: object["icon"] as? String ?? "note.text",
            defaultSpace: (object["defaultSpace"] as? String).map(SpaceName.init(rawValue:)),
            fields: object["fields"] as? [String] ?? [],
            titlePattern: object["titlePattern"] as? String,
            branchPattern: object["branchPattern"] as? String,
            statuses: object["statuses"] as? [String] ?? [],
            doneStatuses: object["doneStatuses"] as? [String] ?? []
        )
    }

    private static func object(for type: NoteType) -> [String: Any] {
        var object: [String: Any] = [
            "version": 1,
            "type": type.name,
            "title": type.title,
            "icon": type.icon,
            "fields": type.fields,
        ]
        object["defaultSpace"] = type.defaultSpace?.rawValue
        object["titlePattern"] = type.titlePattern
        object["branchPattern"] = type.branchPattern
        if type.statuses.isEmpty == false {
            object["statuses"] = type.statuses
            object["doneStatuses"] = type.doneStatuses
        }
        return object
    }
}
