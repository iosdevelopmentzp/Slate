import Foundation
import SlateDomain
import SlateUI
import Testing
@testable import SlatePresentation

@Suite struct NoteChipsMapperTests {
    private func document(path: String = "Tasks/A.md", header: NoteHeader, opaque: String? = nil) -> NoteDocument {
        let vaultPath = VaultPath(rawValue: path)
        return NoteDocument(path: vaultPath, header: header, body: "", hash: ContentHash(rawValue: "h"), meta: FileMeta(path: vaultPath, created: .now, modified: .now, size: 0), opaqueHeader: opaque)
    }

    @Test func taskShowsKindTicketStatusFolderAndTags() {
        let header = NoteHeader(title: "A", type: "task", tags: ["audio"], ticket: "ABC-1", status: "active")

        let chips = NoteChipsMapper.chips(for: document(header: header), type: .task)

        #expect(chips.map(\.text) == ["Task", "ABC-1", "In progress", "Tasks", "#audio"])
        #expect(chips[2].tint == .blue)
    }

    @Test func plainNoteShowsOnlyItsFolder() {
        let chips = NoteChipsMapper.chips(for: document(path: "Inbox/A.md", header: NoteHeader(title: "A")), type: .note)

        #expect(chips.map(\.text) == ["Inbox"])
    }

    @Test func opaqueHeaderSaysTheDetailsAreReadOnly() {
        let chips = NoteChipsMapper.chips(for: document(path: "Inbox/A.md", header: NoteHeader(title: "A"), opaque: "---\n---\n"), type: .note)

        #expect(chips.last?.text == "Details read-only")
    }
}
