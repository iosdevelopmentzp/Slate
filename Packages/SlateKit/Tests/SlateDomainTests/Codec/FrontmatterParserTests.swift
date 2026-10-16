import Foundation
import Testing
@testable import SlateDomain

@Suite struct FrontmatterParserTests {
    @Test func readsEveryKnownKey() throws {
        let text = """
        ---
        id: 9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d
        title: ABC-2324 Profile screen leaks memory
        type: task
        created: 2026-10-16T09:12:33+03:00
        updated: 2026-10-16T10:01:02+03:00
        tags: [audio, memory]
        pinned: false
        ticket: ABC-2324
        branch: feature/ABC-2324-profile-screen-leaks-memory
        mr: https://gitlab.example.com/group/project/-/merge_requests/1234
        status: active
        language: swift
        aliases: [Leak, "Profile leak"]
        due: 2026-10-20
        ---
        ## Context

        """

        let result = FrontmatterParser.parse(text)

        let header = result.header
        #expect(result.hasHeader)
        #expect(result.opaqueHeader == nil)
        #expect(header.id == NoteID(rawValue: "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d"))
        #expect(header.title == "ABC-2324 Profile screen leaks memory")
        #expect(header.type == "task")
        #expect(header.created == Date(timeIntervalSince1970: 1_792_131_153))
        #expect(header.tags == ["audio", "memory"])
        #expect(header.pinned == false)
        #expect(header.ticket == "ABC-2324")
        #expect(header.branch == "feature/ABC-2324-profile-screen-leaks-memory")
        #expect(header.mr == "https://gitlab.example.com/group/project/-/merge_requests/1234")
        #expect(header.status == "active")
        #expect(header.language == "swift")
        #expect(header.aliases == ["Leak", "Profile leak"])
        #expect(header.due == "2026-10-20")
        #expect(header.unknownLines.isEmpty)
        #expect(result.body == "## Context\n")
    }

    @Test func fileWithoutHeaderIsAllBody() {
        let result = FrontmatterParser.parse("# Title\n\nText\n")

        #expect(result.hasHeader == false)
        #expect(result.header == NoteHeader())
        #expect(result.body == "# Title\n\nText\n")
    }

    @Test func unclosedHeaderIsBody() {
        let text = "---\ntitle: Open\n\nNo closing line\n"

        let result = FrontmatterParser.parse(text)

        #expect(result.hasHeader == false)
        #expect(result.body == text)
    }

    @Test func unknownKeysAreKeptInOrder() {
        let text = "---\ntitle: A\nzeta: 1\nalpha: two words\npublish: true\n---\nBody"

        let header = FrontmatterParser.parse(text).header

        #expect(header.unknownLines == ["zeta: 1", "alpha: two words", "publish: true"])
    }

    @Test func emptyLinesAndCommentsAreDropped() {
        let text = "---\n# a comment\ntitle: A\n\n---\n"

        let result = FrontmatterParser.parse(text)

        #expect(result.header.title == "A")
        #expect(result.header.unknownLines.isEmpty)
        #expect(result.opaqueHeader == nil)
    }

    @Test(arguments: [
        "---\ntitle: A\nauthor:\n  name: Kim\n---\nBody",
        "---\ntitle: A\nsummary: |\n  line\n---\nBody",
        "---\ntitle: A\nlist:\n- one\n---\nBody",
        "---\ntitle: A\nbase: &anchor value\n---\nBody",
        "---\ntitle: A\nmeta: {a: 1}\n---\nBody",
    ])
    func unsupportedYAMLMakesTheHeaderOpaque(text: String) {
        let result = FrontmatterParser.parse(text)

        #expect(result.opaqueHeader != nil)
        #expect(result.header.title == "A")
        #expect(result.body == "Body")
    }

    @Test func opaqueHeaderKeepsTheRawBytes() throws {
        let raw = "---\ntitle: A\nauthor:\n  name: Kim\n---\n"

        let result = FrontmatterParser.parse(raw + "Body")

        #expect(result.opaqueHeader == raw)
    }

    @Test func quotedStringsUnescape() {
        let text = #"""
        ---
        title: "Say \"hi\": now"
        ticket: 'it''s'
        ---
        """#

        let header = FrontmatterParser.parse(text + "\n").header

        #expect(header.title == #"Say "hi": now"#)
        #expect(header.ticket == "it's")
    }

    @Test func listItemsMayBeQuotedAndListsMayBeEmpty() {
        let text = "---\ntags: [a, \"b, c\", d]\naliases: []\n---\n"

        let header = FrontmatterParser.parse(text).header

        #expect(header.tags == ["a", "b, c", "d"])
        #expect(header.aliases == [])
    }

    @Test func nullValuesStayNil() {
        let text = "---\ntitle:\nticket:\n---\n"

        let header = FrontmatterParser.parse(text).header

        #expect(header.title == nil)
        #expect(header.ticket == nil)
        #expect(header.unknownLines.isEmpty)
    }

    @Test func knownKeyWithAWrongTypeIsKeptAsAnUnknownLine() {
        let text = "---\npinned: yes\ncreated: yesterday\n---\n"

        let header = FrontmatterParser.parse(text).header

        #expect(header.pinned == nil)
        #expect(header.created == nil)
        #expect(header.unknownLines == ["pinned: yes", "created: yesterday"])
    }

    @Test func carriageReturnsAreTolerated() {
        let text = "---\r\ntitle: Windows\r\n---\r\nBody\r\n"

        let result = FrontmatterParser.parse(text)

        #expect(result.header.title == "Windows")
        #expect(result.body == "Body\r\n")
    }

    @Test func roundTripKeepsTheHeader() {
        let header = NoteHeader(
            id: NoteID(rawValue: "1f0e"),
            title: "true",
            type: "task",
            created: Date(timeIntervalSince1970: 1_792_131_153),
            updated: Date(timeIntervalSince1970: 1_792_134_062),
            tags: ["a", "b c", "d,e"],
            pinned: true,
            ticket: "ABC-1",
            branch: "feature/ABC-1-x",
            mr: "!12",
            status: "review",
            language: "swift",
            aliases: ["#x"],
            due: "2026-10-20",
            unknownLines: ["custom: value"]
        )
        let text = FrontmatterWriter.write(header, timeZone: TimeZone(secondsFromGMT: 3 * 3_600) ?? .gmt) + "Body"

        let result = FrontmatterParser.parse(text)

        #expect(result.header == header)
        #expect(result.body == "Body")
    }
}
