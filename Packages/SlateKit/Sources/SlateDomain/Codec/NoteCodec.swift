import Foundation

package enum NoteCodec {

    package static func decode(_ contents: FileContents) throws -> NoteDocument {
        guard let text = String(data: contents.data, encoding: .utf8) else {
            throw VaultError.notText(contents.meta.path)
        }
        let parsed = FrontmatterParser.parse(text)
        return NoteDocument(
            path: contents.meta.path,
            header: parsed.header,
            body: parsed.body,
            hash: contents.hash,
            meta: contents.meta,
            opaqueHeader: parsed.opaqueHeader
        )
    }

    package static func encode(header: NoteHeader, body: String, opaqueHeader: String?, timeZone: TimeZone) -> Data {
        let headerText = opaqueHeader ?? FrontmatterWriter.write(header, timeZone: timeZone)
        return Data((headerText + body).utf8)
    }
}
