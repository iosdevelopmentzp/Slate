import Foundation
import Testing
@testable import SlateEditor

@MainActor
@Suite struct OutlineItemTests {

    @Test func headingsComeInOrderWithTheirLevels() {
        let text = MarkdownReader.read("# Plan\n\nIntro\n\n## Steps\n\n### First\n\n- not a heading\n\n## Log\n")

        let items = OutlineItem.items(in: text)

        #expect(items.map(\.title) == ["Plan", "Steps", "First", "Log"])
        #expect(items.map(\.level) == [0, 1, 2, 1])
        #expect(items.map { (text.string as NSString).substring(with: NSRange(location: $0.location, length: $0.title.count)) } == ["Plan", "Steps", "First", "Log"])
    }

    @Test func theCurrentHeadingIsTheLastOneBeforeTheCaret() {
        let items = [OutlineItem(title: "A", level: 1, location: 0), OutlineItem(title: "B", level: 1, location: 10)]

        #expect(OutlineItem.current(in: items, at: 5)?.title == "A")
        #expect(OutlineItem.current(in: items, at: 10)?.title == "B")
        #expect(OutlineItem.current(in: [OutlineItem(title: "A", level: 1, location: 3)], at: 1) == nil)
    }

    @Test func aNoteWithoutHeadingsHasNoItems() {
        #expect(OutlineItem.items(in: MarkdownReader.read("Just text\n")).isEmpty)
    }
}
