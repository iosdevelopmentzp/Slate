import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct RichTextControllerFormatJSONTests {
    private func harness(_ markdown: String) -> (EditorHarness, NoticeBox) {
        let harness = EditorHarness(markdown: markdown)
        let box = NoticeBox()
        harness.controller.handlers.notice = { box.values.append($0) }
        return (harness, box)
    }

    @Test func selectedLinesOfJSONBecomeOneJSONBlock() {
        let (harness, _) = harness("payload\n\n{\n\n\"a\" : 1,\n\n\"b\" : [true]\n\n}\n\nend\n")
        let text = harness.text as NSString
        let start = text.range(of: "{").location
        harness.select(start, NSMaxRange(text.range(of: "}")) - start)

        harness.controller.perform(.formatJSON)

        #expect(harness.markdown == "payload\n\n```json\n{\n  \"a\": 1,\n  \"b\": [\n    true\n  ]\n}\n```\n\nend\n")
    }

    @Test func withoutASelectionTheCodeBlockAtTheCaretIsFormatted() {
        let (harness, _) = harness("```\n{\"a\":{\"b\":null}}\n```\n")
        harness.select(3)

        harness.controller.perform(.formatJSON)

        #expect(harness.markdown == "```json\n{\n  \"a\": {\n    \"b\": null\n  }\n}\n```\n")
    }

    @Test func jsonInsideALineKeepsTheTextAroundIt() {
        let (harness, _) = harness("Send {\"a\":1} now\n")
        harness.selectText("{\"a\":1}")

        harness.controller.perform(.formatJSON)

        #expect(harness.markdown == "Send\n\n```json\n{\n  \"a\": 1\n}\n```\n\nnow\n")
    }

    @Test func oneUndoBringsTheOldTextBack() {
        let (harness, _) = harness("{\"a\":1}\n")
        harness.select(0, 7)

        harness.undoStep { harness.controller.perform(.formatJSON) }
        harness.controller.undoEdit()

        #expect(harness.markdown == "{\"a\":1}\n")
    }

    @Test func textThatIsNotJSONStaysAndSaysSo() {
        let (harness, box) = harness("{\"a\":}\n")
        harness.select(0, 6)

        harness.controller.perform(.formatJSON)

        #expect(harness.markdown == "{\"a\":}\n")
        #expect(box.values == ["The selection is not valid JSON"])
    }

    @Test func nothingSelectedOutsideACodeBlockAsksForASelection() {
        let (harness, box) = harness("Text\n")
        harness.select(2)

        harness.controller.perform(.formatJSON)

        #expect(box.values == ["Select the JSON to format"])
    }
}
