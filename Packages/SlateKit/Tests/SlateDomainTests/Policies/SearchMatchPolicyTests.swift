import Foundation
import Testing
@testable import SlateDomain

@Suite struct SearchMatchPolicyTests {
    private func note(_ title: String, body: String, tags: [String] = [], type: String = "note") -> IndexedNote {
        let summary = NoteSummary(id: NoteID(rawValue: title), path: VaultPath(rawValue: "Notes/\(title).md"), title: title, type: type, updated: Date(timeIntervalSince1970: 1), preview: "", tags: tags)
        return IndexedNote(summary: summary, state: IndexedFileState(modified: .distantPast, size: 0, hash: ContentHash(rawValue: "")), body: body)
    }

    @Test func allTermsMustMatch() {
        let query = SearchQuery(terms: ["retain", "engine"])

        #expect(SearchMatchPolicy.matches(note("A", body: "retain cycle in the audio engine"), query))
        #expect(SearchMatchPolicy.matches(note("B", body: "retain cycle"), query) == false)
    }

    @Test func filtersAndExclusions() {
        let audio = note("A", body: "x", tags: ["audio/engine"], type: "task")

        #expect(SearchMatchPolicy.matches(audio, SearchQuery(filters: [.tag("audio"), .type("task")])))
        #expect(SearchMatchPolicy.matches(audio, SearchQuery(excludedFilters: [.tag("audio")])) == false)
        #expect(SearchMatchPolicy.matches(audio, SearchQuery(excludedTerms: ["x"])) == false)
    }

    @Test func excerptCentresOnTheFirstMatch() {
        let body = String(repeating: "lorem ", count: 30) + "retain cycle " + String(repeating: "ipsum ", count: 30)

        let excerpt = SearchMatchPolicy.excerpt(of: body, words: ["retain"])

        #expect(excerpt.hasPrefix("…"))
        #expect(excerpt.contains("retain cycle"))
    }
}
