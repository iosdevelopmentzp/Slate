import Foundation
import Testing
@testable import SlateEditor

@Suite struct OutlineItemTests {
    @Test func headingsOutsideCodeWithTheirOffsets() {
        let items = OutlineItem.items(in: "# Plan\ntext\n```\n# not\n```\n## Context\n#")

        #expect(items.map(\.title) == ["Plan", "Context"])
        #expect(items.map(\.level) == [1, 2])
        #expect(items.last?.location == 26)
    }
}
