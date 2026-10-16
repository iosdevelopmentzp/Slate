import Foundation
import Testing
@testable import SlateDomain

@Suite struct URLCommandParserTests {
    private func parse(_ text: String) -> URLCommand? {
        URL(string: text).flatMap(URLCommandParser.parse)
    }

    @Test func newCarriesTheDraft() {
        #expect(parse("slate://new?title=Hi&body=Text&space=Notes&type=Task&ticket=ABC-1") == .new(NoteDraft(title: "Hi", type: "task", space: SpaceName(rawValue: "Notes"), ticket: "ABC-1", body: "Text\n")))
        #expect(parse("slate://new") == .new(NoteDraft()))
    }

    @Test func openTargets() {
        #expect(parse("slate://open?ticket=ABC-2324") == .open(.ticket("ABC-2324")))
        #expect(parse("slate://open?id=a1") == .open(.id(NoteID(rawValue: "a1"))))
        #expect(parse("slate://open?title=Plan%20B") == .open(.title("Plan B")))
        #expect(parse("slate://open") == nil)
    }

    @Test func appendTargets() {
        #expect(parse("slate://append?today=1&text=Hello") == .append(text: "Hello", target: .today, section: nil))
        #expect(parse("slate://append?ticket=ABC-1&section=Findings&text=x") == .append(text: "x", target: .ticket("ABC-1"), section: "Findings"))
        #expect(parse("slate://append?today=1") == nil)
    }

    @Test func captureAndSearch() {
        #expect(parse("slate://capture") == .capture)
        #expect(parse("slate://search?q=tag:audio") == .search("tag:audio"))
    }

    @Test func otherSchemesRoutesAndUnsafeFoldersAreRejected() {
        #expect(parse("https://new?title=x") == nil)
        #expect(parse("slate://delete?id=x") == nil)
        #expect(parse("slate://new?space=../etc") == .new(NoteDraft()))
        #expect(parse("slate://new?space=.slate") == .new(NoteDraft()))
    }
}
