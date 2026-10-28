import CoreGraphics
import CoreText
import Foundation
import SlateDomain
import Testing
@testable import SlateData

@Suite struct IndexedNoteBuilderTests {
    private func document(header: NoteHeader, body: String) -> NoteDocument {
        let path = VaultPath(rawValue: "Tasks/ABC-1 Fix.md")
        return NoteDocument(path: path, header: header, body: body, hash: ContentHash(rawValue: "h"), meta: FileMeta(path: path, created: Date(timeIntervalSince1970: 10), modified: Date(timeIntervalSince1970: 20), size: 42))
    }

    private func pdf(with text: String) throws -> Data {
        let data = NSMutableData()
        var box = CGRect(x: 0, y: 0, width: 300, height: 200)
        let consumer = try #require(CGDataConsumer(data: data as CFMutableData))
        let context = try #require(CGContext(consumer: consumer, mediaBox: &box, nil))
        context.beginPDFPage(nil)
        let font = CTFontCreateWithName("Helvetica" as CFString, 14, nil)
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: [NSAttributedString.Key(kCTFontAttributeName as String): font]))
        context.textPosition = CGPoint(x: 20, y: 100)
        CTLineDraw(line, context)
        context.endPDFPage()
        context.closePDF()
        return data as Data
    }

    @Test func textOfAFileComesFromUTF8OrFromAPDF() throws {
        let builder = IndexedNoteBuilder()

        #expect(builder.text(ofFile: VaultPath(rawValue: "Work/App.swift"), data: Data("let a = 1".utf8)) == "let a = 1")
        #expect(builder.text(ofFile: VaultPath(rawValue: "Work/shot.png"), data: Data("png".utf8)) == nil)
        #expect(builder.text(ofFile: VaultPath(rawValue: "Work/blob.bin2"), data: Data([0, 1, 2])) == nil)
        let text = builder.text(ofFile: VaultPath(rawValue: "Work/spec.pdf"), data: try pdf(with: "Release checklist"))
        #expect(text?.contains("Release checklist") == true)
    }

    @Test func countsHeadingsOutsideCodeFences() {
        let body = """
        # Title

        ## Section

        ```
        # not a heading
        ```
        """

        #expect(IndexedNoteBuilder().headingCount(in: body) == 2)
    }

    @Test func summaryComesFromTheHeaderAndTheBody() {
        let body = """
        ## Plan

        - [x] Reproduce
        - [ ] Fix
        - [ ] Test

        ![](../_attachments/a.png)
        [log](../_attachments/log.txt)
        ![](../_attachments/a.png)
        [site](https://example.com)
        """
        let header = NoteHeader(id: NoteID(rawValue: "x"), title: "ABC-1 Fix", type: "task", updated: Date(timeIntervalSince1970: 30), pinned: true, ticket: "ABC-1", status: "review")

        let note = IndexedNoteBuilder().build(document(header: header, body: body))

        let summary = note.summary
        #expect(summary.id == NoteID(rawValue: "x"))
        #expect(summary.title == "ABC-1 Fix")
        #expect(summary.type == "task")
        #expect(summary.status == .review)
        #expect(summary.ticket == "ABC-1")
        #expect(summary.pinned)
        #expect(summary.openTodos == 2)
        #expect(summary.attachmentCount == 2)
        #expect(summary.updated == Date(timeIntervalSince1970: 30))
        #expect(summary.created == Date(timeIntervalSince1970: 10))
        #expect(summary.preview.hasPrefix("Plan Reproduce Fix Test"))
        #expect(note.state == IndexedFileState(modified: Date(timeIntervalSince1970: 20), size: 42, hash: ContentHash(rawValue: "h")))
    }

    @Test func headerlessNoteUsesTheFileDatesAndThePathID() {
        let note = IndexedNoteBuilder().build(document(header: NoteHeader(), body: "text"))

        #expect(note.summary.id == NoteID(rawValue: "path:Tasks/ABC-1 Fix.md"))
        #expect(note.summary.title == "ABC-1 Fix")
        #expect(note.summary.updated == Date(timeIntervalSince1970: 20))
        #expect(note.summary.status == nil)
    }
}
