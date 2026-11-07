import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct RichTextControllerWikiCompletionTests {
    private func harness(_ markdown: String = "see\n") -> EditorHarness {
        let harness = EditorHarness(markdown: markdown)
        harness.controller.handlers.noteNames = { ["Trip Plan", "Release plan", "Daily"] }
        harness.select(3)
        return harness
    }

    private func waitForList(_ harness: EditorHarness) async {
        await harness.controller.wikiNamesTask?.value
    }

    @Test func typingTwoBracketsListsNotesAndReturnInsertsTheLink() async throws {
        let harness = harness()

        harness.type(" [[tri")
        await waitForList(harness)
        let list = harness.controller.suggestionList
        #expect(list.isHidden == false)
        #expect(list.suggestions.first?.name == "Trip Plan")
        harness.command(#selector(NSResponder.insertNewline(_:)))

        #expect(harness.markdown == "see [[Trip Plan]]\n")
        #expect(list.isHidden)
    }

    @Test func theArrowsMoveTheChoice() async throws {
        let harness = harness()

        harness.type(" [[plan")
        await waitForList(harness)
        harness.command(#selector(NSResponder.moveDown(_:)))
        harness.command(#selector(NSResponder.insertTab(_:)))

        #expect(harness.markdown == "see [[Trip Plan]]\n")
    }

    @Test func escapeClosesTheListAndKeepsTheText() async throws {
        let harness = harness()

        harness.type(" [[tri")
        await waitForList(harness)
        harness.command(#selector(NSResponder.cancelOperation(_:)))

        #expect(harness.controller.suggestionList.isHidden)
        #expect(harness.text.hasPrefix("see [[tri"))
    }

    @Test func closingBracketsTurnTheTextIntoALink() {
        let harness = harness()

        harness.type(" [[Trip Plan|the trip]] now")

        #expect(harness.markdown == "see [[Trip Plan|the trip]] now\n")
        #expect(harness.controller.storage.attribute(.slateHref, at: 5, effectiveRange: nil) as? String == "wiki:Trip Plan")
    }

    @Test func aCodeBlockGetsNoList() async throws {
        let harness = harness("```\nx\n```\n")
        harness.select(1)

        harness.type(" [[tri")

        #expect(harness.controller.wikiNamesTask == nil)
        #expect(harness.controller.suggestionList.isHidden)
    }
}
