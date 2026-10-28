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

    static func viewerDetail(for meta: FileMeta, content: FileViewerStore.Content, now: Date) -> String {
        let base = model(for: meta, now: now).detail
        switch content {
        case .text: return "\(base) · Plain text"
        case .preview: return "\(base) · Preview only, open the file to change it"
        case .loading, .missing: return base
        }
    }
}
