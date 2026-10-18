import Foundation
import SlateDomain
import SlateUI

enum FolderRowMapper {

    static func model(for space: Space, count: Int, defaultFolder: SpaceName) -> FolderRowModel {
        var model = FolderRowModel(
            id: FolderPath(space: space.folder),
            title: space.folder.rawValue,
            icon: icon(for: space),
            tint: FolderTint.tint(space.color),
            color: space.color,
            count: count,
            canDelete: space.folder != defaultFolder,
            deleteQuestion: question(for: space.folder.rawValue, count: count, target: defaultFolder.rawValue)
        )
        model.isProject = space.isProject
        model.repository = space.project?.repositories.first
        return model
    }

    static func model(forSubfolder folder: FolderPath, space: Space?, count: Int) -> FolderRowModel {
        let color = space?.color ?? .blue
        return FolderRowModel(
            id: folder,
            title: folder.name,
            icon: "folder",
            tint: FolderTint.tint(color),
            color: color,
            count: count,
            canDelete: true,
            deleteQuestion: question(for: folder.name, count: count, target: folder.parent?.name ?? folder.space.rawValue)
        )
    }

    static func icon(for space: Space) -> String {
        guard let icon = space.icon, icon.isEmpty == false, icon != "folder" else { return "folder.fill" }
        return icon
    }

    private static func question(for folder: String, count: Int, target: String) -> String {
        let name = "\u{201C}\(folder)\u{201D}"
        switch count {
        case 0: return "Delete \(name)? It has no notes."
        case 1: return "Delete \(name)? Its note moves to \(target)."
        default: return "Delete \(name)? Its \(count) notes move to \(target)."
        }
    }
}
