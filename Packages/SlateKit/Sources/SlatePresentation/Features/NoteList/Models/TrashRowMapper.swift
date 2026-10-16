import Foundation
import SlateDomain
import SlateUI

enum TrashRowMapper {

    static func model(for item: TrashItem, now: Date) -> TrashRowModel {
        let origin = item.originalPath.space.map { "From \($0.rawValue)" } ?? "From the notes folder"
        return TrashRowModel(id: item.path, title: item.originalPath.stem, detail: "\(origin) · \(item.trashedAt.relativeDescription(to: now))")
    }
}
