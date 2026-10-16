import Foundation
import SlateDomain
import SlateUI

enum FolderRowMapper {

    static func model(for space: Space, count: Int, defaultFolder: SpaceName) -> FolderRowModel {
        FolderRowModel(
            id: space.folder,
            title: space.folder.rawValue,
            icon: icon(for: space),
            tint: FolderTint.tint(space.color),
            color: space.color,
            count: count,
            canDelete: space.folder != defaultFolder,
            deleteQuestion: question(for: space.folder, count: count, target: defaultFolder)
        )
    }

    static func icon(for space: Space) -> String {
        guard let icon = space.icon, icon.isEmpty == false, icon != "folder" else { return "folder.fill" }
        return icon
    }

    private static func question(for folder: SpaceName, count: Int, target: SpaceName) -> String {
        let name = "\u{201C}\(folder.rawValue)\u{201D}"
        switch count {
        case 0: return "Delete \(name)? It has no notes."
        case 1: return "Delete \(name)? Its note moves to \(target.rawValue)."
        default: return "Delete \(name)? Its \(count) notes move to \(target.rawValue)."
        }
    }
}
