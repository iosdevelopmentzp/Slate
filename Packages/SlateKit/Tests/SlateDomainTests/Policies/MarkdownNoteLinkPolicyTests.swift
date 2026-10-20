import Foundation
import Testing
@testable import SlateDomain

@Suite struct MarkdownNoteLinkPolicyTests {
    private func targets(_ body: String) -> [String] {
        MarkdownNoteLinkPolicy.targets(in: MarkdownText.proseLines(of: body))
    }

    @Test func linksToNoteFilesGiveTheirStems() {
        #expect(targets("See [the plan](Plan.md) and [log](../Other/Session%20Log.md).") == ["Plan", "Session Log"])
        #expect(targets("Spaces: [x](<My Note.md>)") == ["My Note"])
    }

    @Test func webAddressesImagesAndCodeAreNotNoteLinks() {
        #expect(targets("[site](https://example.com/readme.md) ![pic](a.md) `[x](B.md)` [y](file.txt)").isEmpty)
    }

    @Test func aLineMentionsANoteByWikilinkOrMarkdownLink() {
        let lines = MarkdownText.proseLines(of: "a [[Plan|the plan]]\nb [p](Plan.md)\nc [[Other]]")

        #expect(lines.map { MarkdownNoteLinkPolicy.mentions($0, stem: "plan") } == [true, true, false])
    }
}
