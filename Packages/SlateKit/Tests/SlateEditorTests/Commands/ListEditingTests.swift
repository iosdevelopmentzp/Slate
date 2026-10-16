import Foundation
import Testing
@testable import SlateEditor

@Suite struct ListEditingTests {
    private func newline(_ text: String, at caret: Int) -> String? {
        let ns = text as NSString
        guard let edit = ListEditing.newline(in: ns, selection: NSRange(location: caret, length: 0)) else { return nil }
        return ns.replacingCharacters(in: edit.range, with: edit.replacement)
    }

    @Test func enterContinuesABulletList() {
        #expect(newline("- one", at: 5) == "- one\n- ")
    }

    @Test func enterKeepsTheIndentAndMarker() {
        #expect(newline("  * one", at: 7) == "  * one\n  * ")
    }

    @Test func enterContinuesACheckboxWithAnOpenBox() {
        #expect(newline("- [x] done", at: 10) == "- [x] done\n- [ ] ")
    }

    @Test func enterOnAnEmptyItemRemovesTheMarker() {
        #expect(newline("- one\n- ", at: 8) == "- one\n")
    }

    @Test func enterOnAnEmptyCheckboxRemovesIt() {
        #expect(newline("- [ ] ", at: 6) == "")
    }

    @Test func enterInsideTheMarkerDoesNothingSpecial() {
        #expect(newline("- one", at: 1) == nil)
    }

    @Test func enterInAPlainLineDoesNothingSpecial() {
        #expect(newline("hello", at: 5) == nil)
    }

    @Test func enterRenumbersAnOrderedList() {
        #expect(newline("1. a\n2. b\n3. c", at: 4) == "1. a\n2. \n3. b\n4. c")
    }

    @Test func enterRenumbersAcrossNestedItems() {
        #expect(newline("1. a\n   - x\n2. b", at: 4) == "1. a\n2. \n   - x\n3. b")
    }

    @Test func enterSplitsTheItemAtTheCaret() {
        #expect(newline("- onetwo", at: 5) == "- one\n- two")
    }

    @Test func enterContinuesAQuote() {
        #expect(newline("> said", at: 6) == "> said\n> ")
    }

    @Test func enterContinuesAListInsideAQuote() {
        #expect(newline("> - item", at: 8) == "> - item\n> - ")
    }

    @Test func enterOnAnEmptyQuoteEndsIt() {
        #expect(newline("> a\n> ", at: 6) == "> a\n")
    }

    @Test func tabIndentsByTheMarkerWidth() throws {
        let text = "- a\n1. b" as NSString
        let edit = try #require(ListEditing.indent(in: text, selection: NSRange(location: 0, length: text.length), outdent: false))

        #expect(text.replacingCharacters(in: edit.range, with: edit.replacement) == "  - a\n   1. b")
    }

    @Test func shiftTabOutdents() throws {
        let text = "    - a" as NSString
        let edit = try #require(ListEditing.indent(in: text, selection: NSRange(location: 6, length: 0), outdent: true))

        #expect(text.replacingCharacters(in: edit.range, with: edit.replacement) == "  - a")
        #expect(edit.selection == NSRange(location: 4, length: 0))
    }

    @Test func tabOutsideAListDoesNothing() {
        #expect(ListEditing.indent(in: "text" as NSString, selection: NSRange(location: 2, length: 0), outdent: false) == nil)
    }
}
