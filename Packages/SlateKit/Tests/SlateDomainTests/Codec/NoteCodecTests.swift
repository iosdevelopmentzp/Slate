import Foundation
import Testing
@testable import SlateDomain

@Suite struct NoteCodecTests {
    private let path = VaultPath(rawValue: "Inbox/Note.md")

    private func contents(_ text: String) -> FileContents {
        let data = Data(text.utf8)
        return FileContents(data: data, hash: .of(data), meta: FileMeta(path: path, created: .distantPast, modified: .distantPast, size: data.count))
    }

    @Test func decodesHeaderAndBody() throws {
        let document = try NoteCodec.decode(contents("---\ntitle: Hello\n---\nBody\n"))

        #expect(document.title == "Hello")
        #expect(document.body == "Body\n")
        #expect(document.path == path)
        #expect(document.isHeaderOpaque == false)
    }

    @Test func fileWithoutHeaderUsesTheStemAndPathID() throws {
        let document = try NoteCodec.decode(contents("Only text"))

        #expect(document.title == "Note")
        #expect(document.type == "note")
        #expect(document.id == NoteID(rawValue: "path:Inbox/Note.md"))
    }

    @Test func opaqueHeaderIsWrittenBackByteForByte() throws {
        let raw = "---\ntitle: A\nauthor:\n  name: Kim\n# keep\n---\n"
        let document = try NoteCodec.decode(contents(raw + "Old body"))

        let data = NoteCodec.encode(header: document.header, body: "New body", opaqueHeader: document.opaqueHeader, timeZone: .gmt)

        #expect(String(decoding: data, as: UTF8.self) == raw + "New body")
    }

    @Test func encodeThenDecodeKeepsTheDocument() throws {
        let header = NoteHeader(id: NoteID(rawValue: "x"), title: "T", type: "note", tags: ["a"])
        let data = NoteCodec.encode(header: header, body: "## H\n\ntext\n", opaqueHeader: nil, timeZone: .gmt)

        let document = try NoteCodec.decode(FileContents(data: data, hash: .of(data), meta: FileMeta(path: path, created: .now, modified: .now, size: data.count)))

        #expect(document.header == header)
        #expect(document.body == "## H\n\ntext\n")
    }

    @Test func nonUTF8DataThrows() {
        let data = Data([0xFF, 0xFE, 0x00, 0xD8])
        let file = FileContents(data: data, hash: .of(data), meta: FileMeta(path: path, created: .now, modified: .now, size: 4))

        #expect(throws: VaultError.notText(path)) {
            try NoteCodec.decode(file)
        }
    }
}
