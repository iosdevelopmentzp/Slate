import Foundation
import SlateDomain
import SlateUI

enum FileRowMapper {
    static func model(for meta: FileMeta, now: Date) -> FileRowModel {
        FileRowModel(
            id: meta.path,
            name: meta.path.fileName,
            detail: "\(ByteFormat.text(Int64(meta.size))) · \(meta.modified.relativeDescription(to: now))",
            isImage: AttachmentPolicy.isImage(meta.path.fileName)
        )
    }
}
