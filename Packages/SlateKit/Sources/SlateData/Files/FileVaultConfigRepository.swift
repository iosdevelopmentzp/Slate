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
        for type in NoteType.builtIn {
            let url = typesFolder.appendingPathComponent("\(type.name).json")
            guard FileManager.default.fileExists(atPath: url.path) == false else { continue }
            try JSONFile.write(Self.object(for: type), to: url)
        }
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
