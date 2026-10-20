import Foundation
import SlateDomain
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct BacklinkRowMapperTests {
    @Test func aRowShowsTitleFolderAndContext() {
        let note = NoteSummary(id: NoteID(rawValue: "a"), path: VaultPath(rawValue: "MyApp/ABC-1 Fix/Notes.md"), title: "Notes", updated: .distantPast, preview: "")

        let model = BacklinkRowMapper.model(for: Backlink(note: note, context: "see [[Plan]]"))

        #expect(model == BacklinkRowModel(id: NoteID(rawValue: "a"), title: "Notes", folder: "MyApp / ABC-1 Fix", context: "see [[Plan]]"))
    }

    @Test func theHintCountsNotes() {
        #expect(BacklinkRowMapper.hint(count: 1) == "1 note links here")
        #expect(BacklinkRowMapper.hint(count: 3) == "3 notes link here")
    }
}
