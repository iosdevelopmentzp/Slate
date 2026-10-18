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

    static func moveTargets(spaces: [Space], tree: FolderTree) -> [MoveTargetModel] {
        let icons = Dictionary(spaces.map { ($0.folder, FolderRowMapper.icon(for: $0)) }, uniquingKeysWith: { first, _ in first })
        return tree.moveTargets(spaces: spaces.map(\.folder)).map { node in
            MoveTargetModel(
                id: node.id,
                title: node.id.components.joined(separator: " › "),
                icon: node.id.isSpace ? (icons[node.id.space] ?? "folder.fill") : "folder"
            )
        }
    }

    static func moveTargets(for summary: NoteSummary, among targets: [MoveTargetModel]) -> [MoveTargetModel] {
        let folder = summary.path.folder
        return targets.filter { $0.id.rawValue != folder }
    }

    static func moveTargets(for summary: NoteSummary, spaces: [Space], folders: [FolderPath]) -> [MoveTargetModel] {
        moveTargets(for: summary, among: moveTargets(spaces: spaces, tree: FolderTree(folders)))
    }
}
