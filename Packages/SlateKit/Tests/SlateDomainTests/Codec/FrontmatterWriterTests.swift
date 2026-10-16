import Foundation
import Testing
@testable import SlateDomain

@Suite struct FrontmatterWriterTests {
    private let timeZone = TimeZone(secondsFromGMT: 3 * 3_600) ?? .gmt

    @Test func writesKnownKeysInTheContractOrderThenUnknownLines() {
        let header = NoteHeader(
            id: NoteID(rawValue: "abc"),
            title: "Note",
            type: "task",
            created: Date(timeIntervalSince1970: 1_792_131_153),
            status: "todo",
            unknownLines: ["zeta: 1"]
        )

        let text = FrontmatterWriter.write(header, timeZone: timeZone)

        #expect(text == """
        ---
        id: abc
        title: Note
        type: task
        created: 2026-10-16T09:12:33+03:00
        status: todo
        zeta: 1
        ---

        """)
    }

    @Test func titleIsWrittenEvenWhenNil() {
        #expect(FrontmatterWriter.write(NoteHeader(), timeZone: timeZone) == "---\ntitle:\n---\n")
    }

    @Test(arguments: [
        ("plain words", "plain words"),
        ("\"quoted", ##""\"quoted""##),
        ("[x]", ##""[x]""##),
        ("#tag", ##""#tag""##),
        ("*star", ##""*star""##),
        ("a: b", ##""a: b""##),
        ("a #b", ##""a #b""##),
        (" lead", ##"" lead""##),
        ("true", ##""true""##),
        ("null", ##""null""##),
        ("~", ##""~""##),
        ("back\\slash \"x\": y", ##""back\\slash \"x\": y""##),
        ("", ##""""##),
    ])
    func quotesOnlyWhenTheRulesSaySo(value: String, expected: String) {
        #expect(FrontmatterWriter.quoted(value) == expected)
    }

    @Test func listItemsWithCommasAreQuoted() {
        let text = FrontmatterWriter.write(NoteHeader(title: "T", tags: ["a", "b,c"]), timeZone: timeZone)

        #expect(text.contains(##"tags: [a, "b,c"]"##))
    }

    @Test func emptyListIsWrittenAsBrackets() {
        let text = FrontmatterWriter.write(NoteHeader(title: "T", tags: []), timeZone: timeZone)

        #expect(text.contains("tags: []"))
    }

    @Test func datesUseTheGivenOffset() {
        let date = Date(timeIntervalSince1970: 1_792_131_153)

        #expect(FrontmatterWriter.date(date, timeZone: timeZone) == "2026-10-16T09:12:33+03:00")
    }
}
