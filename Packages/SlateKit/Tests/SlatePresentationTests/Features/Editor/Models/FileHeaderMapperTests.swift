import Foundation
import SlateDomain
import Testing
@testable import SlatePresentation

@Suite struct FileHeaderMapperTests {
    private func document(_ text: String) -> NoteDocument {
        let parsed = FrontmatterParser.parse(text)
        let path = VaultPath(rawValue: "Notes/A.md")
        return NoteDocument(path: path, header: parsed.header, body: parsed.body, hash: ContentHash(rawValue: "h"), meta: FileMeta(path: path, created: .now, modified: .now, size: 1), opaqueHeader: parsed.opaqueHeader)
    }

    @Test func aHeaderSlateCannotReadIsShownLineByLine() {
        let note = document("---\ntitle: A\naliases:\n  - Trip\n---\nBody\n")

        #expect(FileHeaderMapper.lines(for: note) == ["title: A", "aliases:", "  - Trip"])
    }

    @Test func unknownKeysOfAReadableHeaderAreShown() {
        let note = document("---\ntitle: A\nauthor: Sam\ncssclass: wide\n---\nBody\n")

        #expect(FileHeaderMapper.lines(for: note) == ["author: Sam", "cssclass: wide"])
    }

    @Test func aHeaderWithOnlySlateKeysShowsNothing() {
        #expect(FileHeaderMapper.lines(for: document("---\ntitle: A\npinned: true\n---\nBody\n")) == nil)
        #expect(FileHeaderMapper.lines(for: document("Body\n")) == nil)
    }
}
