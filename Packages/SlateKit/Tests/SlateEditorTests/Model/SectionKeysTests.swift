import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct SectionKeysTests {
    private let text = MarkdownReader.read("## Context\n\nText\n\n### Notes\n\nOne\n\n## Log\n\n### Notes\n\nTwo\n")

    private func location(of needle: String, from start: Int = 0) -> Int {
        let string = text.string as NSString
        return string.range(of: needle, range: NSRange(location: start, length: string.length - start)).location
    }

    @Test func aKeyIsTheLevelAndTheTitle() {
        #expect(SectionKeys.keys(for: [0, location(of: "Notes")], in: text) == ["1 Context", "2 Notes"])
    }

    @Test func aRepeatedHeadingGetsItsNumber() {
        let second = location(of: "Notes", from: location(of: "Log"))

        #expect(SectionKeys.keys(for: [second], in: text) == ["2 Notes #2"])
        #expect(SectionKeys.headings(for: ["2 Notes #2"], in: text) == [second])
    }

    @Test func keysOfHeadingsThatAreGoneAreSkipped() {
        #expect(SectionKeys.headings(for: ["1 Context", "1 Missing"], in: text) == [0])
    }
}
