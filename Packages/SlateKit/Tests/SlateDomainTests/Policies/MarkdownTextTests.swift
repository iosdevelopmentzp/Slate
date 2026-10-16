import Foundation
import Testing
@testable import SlateDomain

@Suite struct MarkdownTextTests {
    @Test func proseLinesSkipFencesAndKeepLineNumbers() {
        let lines = MarkdownText.proseLines(of: "a\n```swift\ncode\n```\nb\n~~~\n```\n~~~\nc")

        #expect(lines.map(\.index) == [0, 4, 8])
        #expect(lines.map(\.text) == ["a", "b", "c"])
    }

    @Test func codeSpansAreFound() {
        #expect(MarkdownText.codeSpans(in: "a `b` c ``d`` e") == [NSRange(location: 2, length: 3), NSRange(location: 8, length: 5)])
    }
}
