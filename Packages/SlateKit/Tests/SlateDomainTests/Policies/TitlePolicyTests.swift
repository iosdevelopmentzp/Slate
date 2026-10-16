import Testing
@testable import SlateDomain

@Suite struct TitlePolicyTests {
    @Test func firstNonEmptyLineBecomesTheTitle() {
        #expect(TitlePolicy.title(fromBody: "\n\n## Engine delegate must be weak\nmore") == "Engine delegate must be weak")
    }

    @Test func listMarksAreRemoved() {
        #expect(TitlePolicy.title(fromBody: "- [ ] Buy milk") == "Buy milk")
    }

    @Test func emptyBodyHasNoTitle() {
        #expect(TitlePolicy.title(fromBody: "  \n\n") == nil)
    }

    @Test func splitTakesTheTicketFromTheStart() {
        let pattern = TrackerSettings.defaultTicketPattern

        #expect(TitlePolicy.split("ABC-2324 Profile screen leaks memory", ticketPattern: pattern) == TitlePolicy.Split(ticket: "ABC-2324", title: "Profile screen leaks memory"))
        #expect(TitlePolicy.split("ABC-12: Fix", ticketPattern: pattern) == TitlePolicy.Split(ticket: "ABC-12", title: "Fix"))
        #expect(TitlePolicy.split("Fix ABC-12 later", ticketPattern: pattern) == TitlePolicy.Split(ticket: nil, title: "Fix ABC-12 later"))
        #expect(TitlePolicy.split("ABC-12", ticketPattern: pattern) == TitlePolicy.Split(ticket: "ABC-12", title: ""))
    }

    @Test func renderUsesThePattern() {
        #expect(TitlePolicy.render("{{ticket}} {{title}}", ticket: "ABC-1", title: "Fix") == "ABC-1 Fix")
        #expect(TitlePolicy.render("{{ticket}} {{title}}", ticket: "ABC-1", title: "") == "ABC-1")
        #expect(TitlePolicy.render(nil, ticket: "ABC-1", title: "Fix") == "Fix")
    }
}
