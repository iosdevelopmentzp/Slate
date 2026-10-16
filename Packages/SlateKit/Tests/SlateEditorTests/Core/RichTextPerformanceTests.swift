import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct RichTextPerformanceTests {
    @Test func longNoteOpensAndTypesWithinBudget() throws {
        let markdown = try EditorHarness.fixture("LongNote")
        let clock = ContinuousClock()
        var harness: EditorHarness?
        let open = clock.measure {
            harness = EditorHarness(markdown: markdown)
        }
        let editor = try #require(harness)
        let middle = (editor.text as NSString).length / 2
        editor.select(middle)
        var samples: [Duration] = []
        for _ in 0..<40 {
            samples.append(clock.measure { editor.type("a") })
        }
        let sorted = samples.sorted()
        let median = sorted[sorted.count / 2]
        print("rich editor timing: open=\(open) median=\(median) worst=\(sorted.last ?? .zero)")
        #expect(median < .milliseconds(16))
        #expect(editor.markdown.contains("aaaa"))
    }
}
