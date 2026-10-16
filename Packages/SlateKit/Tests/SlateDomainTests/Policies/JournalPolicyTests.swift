import Foundation
import Testing
@testable import SlateDomain

@Suite struct JournalPolicyTests {
    private let path = VaultPath(rawValue: "Inbox/A.md")

    private func document(modified: TimeInterval, body: String = "saved") -> NoteDocument {
        NoteDocument(path: path, header: NoteHeader(id: NoteID(rawValue: "a")), body: body, hash: ContentHash(rawValue: "h"), meta: FileMeta(path: path, created: .distantPast, modified: Date(timeIntervalSince1970: modified), size: 1))
    }

    private func entry(at time: TimeInterval, text: String = "typed") -> JournalEntry {
        JournalEntry(noteID: NoteID(rawValue: "a"), path: path, text: text, savedAt: Date(timeIntervalSince1970: time))
    }

    @Test func newerDifferentTextIsOffered() {
        #expect(JournalPolicy.shouldOffer(entry(at: 20), for: document(modified: 10)))
    }

    @Test func olderOrSameTextIsNotOffered() {
        #expect(JournalPolicy.shouldOffer(entry(at: 5), for: document(modified: 10)) == false)
        #expect(JournalPolicy.shouldOffer(entry(at: 20, text: "saved"), for: document(modified: 10)) == false)
        #expect(JournalPolicy.shouldOffer(nil, for: document(modified: 10)) == false)
    }
}
