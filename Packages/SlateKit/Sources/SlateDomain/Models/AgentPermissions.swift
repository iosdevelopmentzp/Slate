import Foundation

package struct AgentPermissions: Hashable, Sendable, Codable {
    package static let fileName = "agents.json"

    package var version: Int
    package var writableFolders: [String]
    package var allowCreate: Bool
    package var allowTrash: Bool

    package init(version: Int = 1, writableFolders: [String] = [SpacesConfig.defaultSpace.rawValue], allowCreate: Bool = true, allowTrash: Bool = false) {
        self.version = version
        self.writableFolders = writableFolders
        self.allowCreate = allowCreate
        self.allowTrash = allowTrash
    }

    package init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = AgentPermissions()
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? defaults.version
        writableFolders = try container.decodeIfPresent([String].self, forKey: .writableFolders) ?? defaults.writableFolders
        allowCreate = try container.decodeIfPresent(Bool.self, forKey: .allowCreate) ?? defaults.allowCreate
        allowTrash = try container.decodeIfPresent(Bool.self, forKey: .allowTrash) ?? defaults.allowTrash
    }

    package func canWrite(in folder: FolderPath) -> Bool {
        guard AgentPathPolicy.isProtected(folder.components) == false else { return false }
        let target = folder.rawValue.lowercased()
        return writableFolders.contains { entry in
            let allowed = AgentPathPolicy.trimmed(entry).lowercased()
            return allowed.isEmpty == false && (target == allowed || target.hasPrefix(allowed + "/"))
        }
    }

    package func checkWrite(_ path: VaultPath) throws {
        guard let folder = path.folderPath, canWrite(in: folder) else {
            throw AgentError.folderNotAllowed(path.folder, allowed: writableFolders)
        }
    }

    package func checkCreate(in folder: FolderPath) throws {
        guard allowCreate else { throw AgentError.createNotAllowed }
        guard canWrite(in: folder) else { throw AgentError.folderNotAllowed(folder.rawValue, allowed: writableFolders) }
    }

    package func checkTrash(_ path: VaultPath) throws {
        guard allowTrash else { throw AgentError.trashNotAllowed }
        try checkWrite(path)
    }

    package func setting(_ folder: String, writable: Bool) -> AgentPermissions {
        var copy = self
        copy.writableFolders.removeAll { StemPolicy.isSame(AgentPathPolicy.trimmed($0), folder) }
        if writable {
            copy.writableFolders.append(folder)
        }
        return copy
    }
}
