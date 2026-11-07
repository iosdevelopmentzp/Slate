import Testing
@testable import SlateEditor

@Suite struct NoteSuggestionTests {
    private let names = ["Release plan", "Trip Plan", "Plans for May", "Daily", "ABC-123 Fix login"]

    @Test func namesThatStartWithTheQueryComeFirst() {
        let found = NoteSuggestion.matches(for: "plan", in: names).map(\.name)

        #expect(found == ["Plans for May", "Release plan", "Trip Plan", "plan"])
    }

    @Test func anExactNameAddsNoNewLink() {
        let found = NoteSuggestion.matches(for: "daily", in: names)

        #expect(found == [NoteSuggestion(name: "Daily", isNew: false)])
    }

    @Test func aNameNobodyHasOffersANewLink() {
        #expect(NoteSuggestion.matches(for: "Zoo", in: names) == [NoteSuggestion(name: "Zoo", isNew: true)])
    }

    @Test func anEmptyQueryListsTheFirstNotes() {
        #expect(NoteSuggestion.matches(for: "", in: names).count == names.count)
    }
}
