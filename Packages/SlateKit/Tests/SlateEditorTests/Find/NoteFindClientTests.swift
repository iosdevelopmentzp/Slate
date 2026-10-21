import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct NoteFindClientTests {
    private let note = "Intro\n\n| a | b |\n|---|---|\n| 1 | milk |\n\nAfter\n"

    private func range(of needle: String, in client: NoteFindClient) -> NSRange {
        let whole = client.segments.items.map(\.string).joined() as NSString
        return whole.range(of: needle)
    }

    @Test func theSearchedTextHoldsTheCells() {
        let harness = EditorHarness(markdown: note)
        let client = harness.controller.findClient
        var effective = NSRange()
        var boundary = ObjCBool(false)
        client.refresh()

        let length = client.stringLength()
        let piece = client.string(at: 11, effectiveRange: &effective, endsWithSearchBoundary: &boundary)

        #expect(length == 19)
        #expect(piece == "milk")
        #expect(effective == NSRange(location: 9, length: 4))
        #expect(boundary.boolValue)
    }

    @Test func selectingAMatchInTheTextSelectsIt() {
        let harness = EditorHarness(markdown: note)
        let client = harness.controller.findClient

        client.selectedRanges = [NSValue(range: range(of: "After", in: client))]

        #expect(harness.textView.selectedRange() == (harness.text as NSString).range(of: "After"))
        #expect(client.firstSelectedRange == range(of: "After", in: client))
    }

    @Test func selectingAMatchInACellPutsTheCaretAtTheTableAndRemembersTheMatch() {
        let harness = EditorHarness(markdown: note)
        let client = harness.controller.findClient
        let match = range(of: "ilk", in: client)

        client.selectedRanges = [NSValue(range: match)]

        #expect(harness.textView.selectedRange() == NSRange(location: 6, length: 0))
        #expect(client.firstSelectedRange == match)
    }

    @Test func aCellMatchIsSelectedInTheCellOnceTheFindBarIsGone() async throws {
        let harness = EditorHarness(markdown: note)
        let client = harness.controller.findClient
        let view = try #require(harness.table()?.loadedView)

        client.selectedRanges = [NSValue(range: range(of: "ilk", in: client))]
        let deadline = Date().addingTimeInterval(2)
        while view.editing == nil, Date() < deadline {
            await Task.yield()
        }

        #expect(view.editing == TableCellIndex(row: 1, column: 1))
        #expect(view.cellEditor.selectedRange() == NSRange(location: 1, length: 3))
        #expect(harness.window.firstResponder === view.cellEditor)
    }

    @Test func aCellMatchHasRectsInTheTableView() throws {
        let harness = EditorHarness(markdown: note)
        let client = harness.controller.findClient
        let match = range(of: "milk", in: client)
        let view = try #require(harness.table()?.loadedView)
        var effective = NSRange()

        let content = client.contentView(at: match.location, effectiveCharacterRange: &effective)
        let rects = try #require(client.rects(forCharacterRange: match)).map(\.rectValue)

        #expect(content === view)
        #expect(effective == NSRange(location: 6, length: 7))
        #expect(rects.count == 1)
        #expect(view.currentLayout.cellRect(TableCellIndex(row: 1, column: 1)).contains(rects[0]))
    }

    @Test func aTextMatchHasRectsInTheTextView() throws {
        let harness = EditorHarness(markdown: note)
        let client = harness.controller.findClient
        var effective = NSRange()

        let content = client.contentView(at: 0, effectiveCharacterRange: &effective)
        let rects = try #require(client.rects(forCharacterRange: NSRange(location: 0, length: 5))).map(\.rectValue)

        #expect(content === harness.textView)
        #expect(rects.count == 1)
        #expect(rects[0].width > 10)
    }

    @Test func theFindIndicatorDrawsTheMatchedText() throws {
        let harness = EditorHarness(markdown: note)
        let client = harness.controller.findClient
        let match = range(of: "Intro", in: client)
        let rect = try #require(client.rects(forCharacterRange: match)?.first?.rectValue)
        let bitmap = try #require(NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 400, pixelsHigh: 200, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0))

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: try #require(NSGraphicsContext(bitmapImageRep: bitmap)).cgContext, flipped: true)
        let context = try #require(NSGraphicsContext.current).cgContext
        context.translateBy(x: 0, y: 200)
        context.scaleBy(x: 1, y: -1)
        client.drawCharacters(in: match, forContentView: harness.textView)
        NSGraphicsContext.restoreGraphicsState()

        let inked = stride(from: Int(rect.minX), to: Int(rect.maxX), by: 1).contains { x in
            stride(from: Int(rect.minY), to: Int(rect.maxY), by: 1).contains { y in
                (bitmap.colorAt(x: x, y: y)?.alphaComponent ?? 0) > 0.5
            }
        }
        #expect(inked)
    }

    @Test func replacingInACellChangesOnlyThatCell() {
        let harness = EditorHarness(markdown: note)
        let client = harness.controller.findClient

        client.replaceCharacters(in: range(of: "milk", in: client), with: "bread")
        client.replaceCharacters(in: range(of: "a", in: client), with: "Item")

        #expect(harness.markdown == "Intro\n\n| Item | b |\n| --- | --- |\n| 1 | bread |\n\nAfter\n")
    }

    @Test func replacingInTheTextKeepsTheTable() {
        let harness = EditorHarness(markdown: note)
        let client = harness.controller.findClient

        client.replaceCharacters(in: range(of: "After", in: client), with: "Later")

        #expect(harness.markdown == "Intro\n\n| a | b |\n|---|---|\n| 1 | milk |\n\nLater\n")
    }

    @Test func theSearchedTextFollowsAnEditWhileTheFindBarIsOpen() {
        let harness = EditorHarness(markdown: note)
        let client = harness.controller.findClient
        client.refresh()
        harness.controller.finder.performAction(.showFindInterface)
        harness.caret(after: "Intro")

        harness.type("duction")

        #expect(client.stringLength() == 26)
    }

    @Test func theFinderUsesTheClient() {
        let harness = EditorHarness(markdown: note)

        #expect(harness.controller.finder.client === harness.controller.findClient)
        #expect(harness.textView.usesFindBar == false)
        #expect(harness.controller.finder.validateAction(.showFindInterface))
    }
}
