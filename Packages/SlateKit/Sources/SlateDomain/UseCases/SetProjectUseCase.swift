import Foundation

package struct SetProjectUseCase: Sendable {
    package static let projectIcon = "shippingbox.fill"

    let config: any VaultConfigRepository

    @discardableResult
    package func execute(_ space: SpaceName, project: ProjectInfo?) async throws -> Space {
        var spaces = try await config.spaces()
        guard let index = spaces.spaces.firstIndex(where: { $0.folder == space }) else {
            throw VaultError.notFound(VaultPath(rawValue: space.rawValue))
        }
        var entry = spaces.spaces[index]
        entry.project = project
        entry.icon = Self.icon(entry.icon, isProject: project != nil)
        spaces.spaces[index] = entry
        try await config.saveSpaces(spaces)
        if project != nil {
            let permissions = try await config.agentPermissions()
            if permissions.canWrite(in: FolderPath(space: space)) == false {
                try await config.saveAgentPermissions(permissions.setting(space.rawValue, writable: true))
            }
        }
        return entry
    }

    private static func icon(_ icon: String?, isProject: Bool) -> String {
        let plain = icon == nil || icon == "folder.fill" || icon == "folder"
        if isProject { return plain ? projectIcon : icon ?? projectIcon }
        return icon == projectIcon ? "folder.fill" : icon ?? "folder.fill"
    }
}
