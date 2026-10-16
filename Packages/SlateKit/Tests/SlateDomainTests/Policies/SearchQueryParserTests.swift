import Foundation
import Testing
@testable import SlateDomain

@Suite struct SearchQueryParserTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let zone = TimeZone(secondsFromGMT: 0)!

    private func parse(_ text: String) -> SearchQuery {
        SearchQueryParser.parse(text, now: now, timeZone: zone)
    }

    @Test func wordsAndPhrases() {
        let query = parse(#"retain cycle "audio engine""#)

        #expect(query.terms == ["retain", "cycle"])
        #expect(query.phrases == ["audio engine"])
    }

    @Test func filters() {
        let query = parse("type:task status:active tag:#Audio space:Tasks ticket:ABC-1 is:todo has:image")

        #expect(query.filters == [.type("task"), .status("active"), .tag("audio"), .space("Tasks"), .ticket("ABC-1"), .state(.todo), .has(.image)])
        #expect(query.terms.isEmpty)
    }

    @Test func exclusions() {
        let query = parse(#"-draft -tag:old -"not this" keep"#)

        #expect(query.excludedTerms == ["draft", "not this"])
        #expect(query.excludedFilters == [.tag("old")])
        #expect(query.terms == ["keep"])
    }

    @Test func quotedFilterValue() {
        #expect(parse(#"space:"My Notes""#).filters == [.space("My Notes")])
    }

    @Test func dates() throws {
        let query = parse("after:2026-09-01 before:-7d")
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone

        #expect(query.filters.first == .after(try #require(calendar.date(from: DateComponents(year: 2026, month: 9, day: 1)))))
        #expect(query.filters.last == .before(try #require(calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: now)))))
    }

    @Test func unknownKeysAndPunctuationStayOrDrop() {
        let query = parse("note:x !!! ABC-123 (")

        #expect(query.terms == ["note:x", "ABC-123"])
    }

    @Test func unknownStateIsAWord() {
        #expect(parse("is:weird").terms == ["is:weird"])
    }

    @Test func unclosedQuoteIsAPhrase() {
        #expect(parse(#""open ended"#).phrases == ["open ended"])
    }

    @Test func emptyTextIsAnEmptyQuery() {
        #expect(parse("   ").isEmpty)
    }
}
