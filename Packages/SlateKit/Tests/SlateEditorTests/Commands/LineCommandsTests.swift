import Foundation
import Testing
@testable import SlateEditor

@Suite struct LineCommandsTests {
    private func apply(_ edit: TextEdit?, to text: String) -> String? {
        guard let edit else { return nil }
        return (text as NSString).replacingCharacters(in: edit.range, with: edit.replacement)
    }

    @Test func moveLineUpAndDown() {
        let text = "one\ntwo\nthree"

        #expect(apply(LineCommands.moveLines(in: text as NSString, selection: NSRange(location: 5, length: 0), up: true), to: text) == "two\none\nthree")
        #expect(apply(LineCommands.moveLines(in: text as NSString, selection: NSRange(location: 5, length: 0), up: false), to: text) == "one\nthree\ntwo")
        #expect(LineCommands.moveLines(in: text as NSString, selection: NSRange(location: 1, length: 0), up: true) == nil)
        #expect(LineCommands.moveLines(in: text as NSString, selection: NSRange(location: 10, length: 0), up: false) == nil)
    }

    @Test func moveKeepsTheCaretOnTheMovedLine() throws {
        let edit = try #require(LineCommands.moveLines(in: "one\ntwo" as NSString, selection: NSRange(location: 5, length: 0), up: true))

        #expect(edit.selection == NSRange(location: 1, length: 0))
    }

    @Test func duplicateCopiesTheLineBelow() {
        let text = "one\ntwo"

        #expect(apply(LineCommands.duplicateLines(in: text as NSString, selection: NSRange(location: 1, length: 0)), to: text) == "one\none\ntwo")
        #expect(apply(LineCommands.duplicateLines(in: text as NSString, selection: NSRange(location: 5, length: 0)), to: text) == "one\ntwo\ntwo")
    }

    @Test func commentTogglesWithTheLanguagePrefix() {
        let text = "  let a = 1\n  let b = 2"
        let commented = apply(LineCommands.toggleComment(in: text as NSString, selection: NSRange(location: 0, length: (text as NSString).length), prefix: "//"), to: text)

        #expect(commented == "  // let a = 1\n  // let b = 2")
        let restored = apply(LineCommands.toggleComment(in: commented! as NSString, selection: NSRange(location: 0, length: (commented! as NSString).length), prefix: "//"), to: commented!)
        #expect(restored == text)
        #expect(LineCommands.commentPrefix(for: "yml") == "#")
        #expect(LineCommands.commentPrefix(for: "swift") == "//")
    }
}
