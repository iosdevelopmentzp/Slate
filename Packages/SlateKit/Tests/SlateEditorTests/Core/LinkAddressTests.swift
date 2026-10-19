import Testing
@testable import SlateEditor

@Suite struct LinkAddressTests {

    @Test func aNoteNameBecomesANoteLinkWithTheNoteSpelling() {
        #expect(LinkAddress.href(for: "trip plan", notes: ["Trip Plan", "Other"]) == "wiki:Trip Plan")
        #expect(LinkAddress.href(for: "[[Other]]", notes: ["Other"]) == "wiki:Other")
    }

    @Test func webAddressesAndPathsStayAsTheyAre() {
        #expect(LinkAddress.href(for: " https://example.com/a ", notes: []) == "https://example.com/a")
        #expect(LinkAddress.href(for: "slack://channel?id=1", notes: []) == "slack://channel?id=1")
        #expect(LinkAddress.href(for: "mailto:me@example.com", notes: []) == "mailto:me@example.com")
        #expect(LinkAddress.href(for: "~/Downloads/report.pdf", notes: []) == "~/Downloads/report.pdf")
    }

    @Test func aDomainWithoutASchemeGetsHttps() {
        #expect(LinkAddress.href(for: "example.com/docs", notes: []) == "https://example.com/docs")
    }

    @Test func otherTextLinksToANoteOfThatName() {
        #expect(LinkAddress.href(for: "New idea", notes: ["Other"]) == "wiki:New idea")
        #expect(LinkAddress.href(for: "a|b]", notes: []) == "wiki:ab")
        #expect(LinkAddress.href(for: "  ", notes: []) == nil)
    }

    @Test func displayAndCopyShowTheNoteName() {
        #expect(LinkAddress.display("wiki:Other") == "Other")
        #expect(LinkAddress.copyText("wiki:Other") == "[[Other]]")
        #expect(LinkAddress.copyText("https://example.com") == "https://example.com")
    }

    @Test func textWithALineBreakCannotBeEdited() {
        #expect(LinkAddress.editableText("map") == "map")
        #expect(LinkAddress.editableText("one\ntwo") == nil)
        #expect(LinkAddress.editableText("one\u{2028}two") == nil)
    }
}
