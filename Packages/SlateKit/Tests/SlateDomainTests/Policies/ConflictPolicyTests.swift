import Foundation
import Testing
@testable import SlateDomain

@Suite struct ConflictPolicyTests {
    private func document(body: String, hash: String) -> NoteDocument {
        let path = VaultPath(rawValue: "Inbox/A.md")
        return NoteDocument(path: path, header: NoteHeader(title: "A"), body: body, hash: ContentHash(rawValue: hash), meta: FileMeta(path: path, created: .now, modified: .now, size: 1))
    }

    @Test func sameHashIsIgnored() {
        #expect(ConflictPolicy.decide(loaded: document(body: "a", hash: "1"), disk: document(body: "a", hash: "1"), isDirty: true) == .ignore)
    }

    @Test func cleanEditorReloads() {
        #expect(ConflictPolicy.decide(loaded: document(body: "a", hash: "1"), disk: document(body: "b", hash: "2"), isDirty: false) == .reload)
    }

    @Test func dirtyEditorAdoptsAHeaderOnlyChange() {
        #expect(ConflictPolicy.decide(loaded: document(body: "a", hash: "1"), disk: document(body: "a", hash: "2"), isDirty: true) == .adoptHeader)
    }

    @Test func dirtyEditorWithAChangedBodyIsAConflict() {
        #expect(ConflictPolicy.decide(loaded: document(body: "a", hash: "1"), disk: document(body: "b", hash: "2"), isDirty: true) == .conflict)
    }
}
