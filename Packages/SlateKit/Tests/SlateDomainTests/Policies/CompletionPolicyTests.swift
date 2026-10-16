import Foundation
import Testing
@testable import SlateDomain

@Suite struct CompletionPolicyTests {
    private func summary(_ stem: String, updated: TimeInterval) -> NoteSummary {
        NoteSummary(id: NoteID(rawValue: stem), path: VaultPath(rawValue: "Notes/\(stem).md"), title: stem, updated: Date(timeIntervalSince1970: updated), preview: "")
    }

    @Test func noteNamesStartWithThePrefixThenContainIt() {
        let notes = [summary("Audio engine", updated: 1), summary("Engine room", updated: 2), summary("Other", updated: 3)]

        #expect(CompletionPolicy.noteNames(matching: "eng", in: notes) == ["Engine room", "Audio engine"])
        #expect(CompletionPolicy.noteNames(matching: "", in: notes) == ["Other", "Engine room", "Audio engine"])
    }

    @Test func tagsAreOrderedByUse() {
        let tags = [TagCount(tag: "api", count: 1), TagCount(tag: "audio", count: 5), TagCount(tag: "ios", count: 9)]

        #expect(CompletionPolicy.tags(matching: "a", in: tags) == ["audio", "api"])
    }
}
