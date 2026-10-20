import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct HeadingSectionTests {
    private let text = MarkdownReader.read("## Context\n\nText\n\n### Detail\n\nMore\n\n## Log\n\nend\n")

    private func location(of needle: String) -> Int {
        (text.string as NSString).range(of: needle).location
    }

    @Test func aSectionRunsToTheNextHeadingOfTheSameLevel() throws {
        let section = try #require(HeadingSection.at(0, in: text))

        #expect(section.level == 1)
        #expect(section.body == NSRange(location: location(of: "Text"), length: location(of: "Log") - location(of: "Text")))
    }

    @Test func aSubheadingSectionEndsAtTheNextHeading() throws {
        let section = try #require(HeadingSection.at(location(of: "Detail"), in: text))

        #expect(section.body == NSRange(location: location(of: "More"), length: location(of: "Log") - location(of: "More")))
    }

    @Test func theLastSectionRunsToTheEnd() throws {
        let section = try #require(HeadingSection.at(location(of: "Log"), in: text))

        #expect(NSMaxRange(section.body) == text.length)
    }

    @Test func aParagraphThatIsNotAHeadingHasNoSection() {
        #expect(HeadingSection.at(location(of: "Text"), in: text) == nil)
        #expect(HeadingSection.at(location(of: "Text") + 1, in: text) == nil)
    }

    @Test func theNearestHeadingAboveContainsALocation() {
        #expect(HeadingSection.containing(location(of: "More"), in: text)?.heading == location(of: "Detail"))
        #expect(HeadingSection.containing(location(of: "Text"), in: text)?.heading == 0)
        #expect(HeadingSection.containing(location(of: "Log") + 1, in: text)?.heading == location(of: "Log"))
        #expect(HeadingSection.containing(0, in: MarkdownReader.read("plain\n")) == nil)
    }

    @Test func allListsOnlyHeadingsWithText() {
        let text = MarkdownReader.read("## Empty\n\n## Full\n\nText\n")

        #expect(HeadingSection.all(in: text).map(\.heading) == [(text.string as NSString).range(of: "Full").location])
    }
}
