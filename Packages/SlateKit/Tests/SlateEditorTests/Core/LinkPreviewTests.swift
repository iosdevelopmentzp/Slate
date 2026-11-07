import Testing
@testable import SlateEditor

@Suite struct LinkPreviewTests {

    @Test func aWebAddressShowsTheSiteAndThePage() {
        let preview = LinkPreview(href: "https://www.example.com/group/project/-/merge_requests/12?tab=diffs#note_3")

        #expect(preview == LinkPreview(href: "https://example.com/group/project/-/merge_requests/12?tab=diffs#note_3"))
        #expect(preview.symbol == "globe")
        #expect(preview.title == "example.com")
        #expect(preview.detail == "group/project/-/merge_requests/12 ?tab=diffs #note_3")
    }

    @Test func aSiteWithoutAPageSaysWebPage() {
        #expect(LinkPreview(href: "https://example.com/").detail == "Web page")
    }

    @Test func aNoteLinkShowsTheNoteName() {
        let preview = LinkPreview(href: "wiki:Trip Plan")

        #expect(preview.symbol == "doc.text")
        #expect(preview.title == "Trip Plan")
        #expect(preview.detail == "Note in Slate")
    }

    @Test func aMailLinkShowsTheAddress() {
        let preview = LinkPreview(href: "mailto:me@example.com")

        #expect(preview.symbol == "envelope")
        #expect(preview.title == "me@example.com")
    }

    @Test func aFileShowsItsNameAndFolder() {
        let preview = LinkPreview(href: "/tmp/reports/week 3.pdf")

        #expect(preview.symbol == "doc")
        #expect(preview.title == "week 3.pdf")
        #expect(preview.detail == "/tmp/reports")
    }

    @Test func anAppLinkShowsTheWholeAddress() {
        let preview = LinkPreview(href: "slack://channel?id=1")

        #expect(preview.symbol == "link")
        #expect(preview.title == "slack://channel?id=1")
        #expect(preview.detail == "Opens in another app")
    }
}
