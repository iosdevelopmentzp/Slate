import Foundation

package struct NoteDocument: Hashable, Sendable {
    package var path: VaultPath
    package var header: NoteHeader
    package var body: String
    package var hash: ContentHash
    package var meta: FileMeta
    package var opaqueHeader: String?

    package init(path: VaultPath, header: NoteHeader, body: String, hash: ContentHash, meta: FileMeta, opaqueHeader: String? = nil) {
        self.path = path
        self.header = header
        self.body = body
        self.hash = hash
        self.meta = meta
        self.opaqueHeader = opaqueHeader
    }

    package var id: NoteID {
        header.id ?? NoteID.forPath(path)
    }

    package var title: String {
        header.title ?? path.stem
    }

    package var type: String {
        header.type ?? NoteType.defaultName
    }

    package var isHeaderOpaque: Bool {
        opaqueHeader != nil
    }
}
