import Foundation
import SlateDomain
import SlateUI

enum NoteRowMapper {

    static func model(for summary: NoteSummary, now: Date) -> NoteRowModel {
        NoteRowModel(
            id: summary.id,
            title: summary.title.isEmpty ? StemPolicy.untitled : summary.title,
            preview: summary.preview,
            date: summary.updated.relativeDescription(to: now),
            isPinned: summary.pinned
        )
    }

    static func moveTargets(for summary: NoteSummary, spaces: [Space], folders: [FolderPath]) -> [MoveTargetModel] {
        FolderTreeMapper.moveTargets(spaces: spaces.map(\.folder), folders: folders)
            .filter { $0.id.rawValue != summary.path.folder }
            .map { node in
                let space = spaces.first { $0.folder == node.id.space }
                return MoveTargetModel(
                    id: node.id,
                    title: node.id.components.joined(separator: " › "),
                    icon: node.id.isSpace ? (space.map(FolderRowMapper.icon(for:)) ?? "folder.fill") : "folder"
                )
            }
    }
}
