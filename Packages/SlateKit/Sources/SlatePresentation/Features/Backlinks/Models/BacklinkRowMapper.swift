import Foundation
import SlateDomain

enum BacklinkRowMapper {
    static func model(for backlink: Backlink) -> BacklinkRowModel {
        let folder = backlink.note.path.folder.replacingOccurrences(of: "/", with: " / ")
        return BacklinkRowModel(id: backlink.id, title: backlink.note.title, folder: folder, context: backlink.context)
    }

    static func buttonTitle(count: Int) -> String {
        "\(count)"
    }

    static func hint(count: Int) -> String {
        count == 1 ? "1 note links here" : "\(count) notes link here"
    }
}
