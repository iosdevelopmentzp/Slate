import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct RichTextControllerDiagramsTests {
    static let note = "Intro\n\n```mermaid\nflowchart LR\n  A --> B\n```\n\nEnd\n"

    private func codeLocation(in harness: EditorHarness) -> Int {
        (harness.text as NSString).range(of: "flowchart").location
    }

    @Test func aDiagramIsDrawnFromTheBlockText() async {
        var sources: [String] = []
        let harness = EditorHarness(markdown: Self.note, drawDiagram: { source, _ in
            sources.append(source)
            return EditorHarness.diagramPicture()
        })

        await harness.waitForDiagrams()

        #expect(sources == ["flowchart LR\n  A --> B"])
        let picture = harness.controller.storage.attribute(.slateDiagram, at: codeLocation(in: harness), effectiveRange: nil) as? DiagramPicture
        #expect(picture?.size == CGSize(width: 200, height: 100))
    }

    @Test func theCodeIsHiddenWhileTheCaretIsOutside() async {
        let harness = EditorHarness(markdown: Self.note)
        await harness.waitForDiagrams()
        let location = codeLocation(in: harness)

        #expect(harness.controller.storage.attribute(.slateDiagramHidden, at: location, effectiveRange: nil) as? Bool == true)
        #expect((harness.font(at: location)?.pointSize ?? 99) < 1)
    }

    @Test func theCodeShowsWhenTheCaretEntersTheBlock() async {
        let harness = EditorHarness(markdown: Self.note)
        await harness.waitForDiagrams()
        let location = codeLocation(in: harness)

        harness.select(location + 2)

        #expect(harness.controller.storage.attribute(.slateDiagramHidden, at: location, effectiveRange: nil) == nil)
        #expect(harness.font(at: location)?.pointSize == 13)

        harness.caret(after: "End")

        #expect(harness.controller.storage.attribute(.slateDiagramHidden, at: location, effectiveRange: nil) as? Bool == true)
    }

    @Test func theDiagramTakesSpaceAboveTheCode() async {
        let harness = EditorHarness(markdown: Self.note)
        await harness.waitForDiagrams()
        let location = codeLocation(in: harness)

        let style = harness.controller.storage.attribute(.paragraphStyle, at: location, effectiveRange: nil) as? NSParagraphStyle
        let area = harness.controller.storage.attribute(.slateDiagramArea, at: location, effectiveRange: nil) as? CGFloat

        #expect(area == 100 + DiagramLayout.topPadding + DiagramLayout.padding)
        #expect((style?.paragraphSpacingBefore ?? 0) > (area ?? 0))
    }

    @Test func theFileKeepsTheCodeBlock() async {
        let harness = EditorHarness(markdown: Self.note)
        await harness.waitForDiagrams()

        harness.select(codeLocation(in: harness) + 2)
        harness.caret(after: "End")

        #expect(harness.markdown == Self.note)
    }

    @Test func typingInTheBlockDrawsTheNewDiagram() async {
        var sources: [String] = []
        let harness = EditorHarness(markdown: Self.note, drawDiagram: { source, _ in
            sources.append(source)
            return EditorHarness.diagramPicture()
        })
        await harness.waitForDiagrams()

        harness.caret(after: "A --> B")
        harness.type("C")
        await harness.waitForDiagrams()

        #expect(sources.last == "flowchart LR\n  A --> BC")
        #expect(harness.markdown.contains("A --> BC"))
    }

    @Test func aBrokenEditKeepsTheLastPictureAndShowsTheError() async {
        let harness = EditorHarness(markdown: Self.note, drawDiagram: { source, _ in
            source.hasSuffix("-->") ? DiagramPicture(image: nil, size: .zero, error: "Parse error") : EditorHarness.diagramPicture()
        })
        await harness.waitForDiagrams()

        harness.caret(after: "A --> B")
        harness.command(#selector(NSResponder.deleteBackward(_:)))
        harness.command(#selector(NSResponder.deleteBackward(_:)))
        await harness.waitForDiagrams()
        try? await Task.sleep(for: .milliseconds(100))
        await harness.waitForDiagrams()

        let picture = harness.controller.storage.attribute(.slateDiagram, at: codeLocation(in: harness), effectiveRange: nil) as? DiagramPicture
        #expect(picture?.image != nil)
        #expect(picture?.error == "Parse error")
    }

    @Test func twoDiagramsInARowAreBothDrawn() async {
        var sources: [String] = []
        let harness = EditorHarness(markdown: "```mermaid\nflowchart LR\n  A --> B\n```\n\n```mermaid\nflowchart LR\n  C --> D\n```\n", drawDiagram: { source, _ in
            sources.append(source)
            return EditorHarness.diagramPicture()
        })

        await harness.waitForDiagrams()

        #expect(harness.controller.diagramParagraphs().count == 2)
        #expect(Set(sources) == ["flowchart LR\n  A --> B", "flowchart LR\n  C --> D"])
    }

    @Test func otherCodeBlocksAreNotDiagrams() async {
        let harness = EditorHarness(markdown: "```swift\nlet a = 1\n```\n")
        await harness.waitForDiagrams()

        #expect(harness.controller.storage.attribute(.slateDiagramArea, at: 0, effectiveRange: nil) == nil)
        #expect(harness.controller.diagrams.task == nil)
    }
}
