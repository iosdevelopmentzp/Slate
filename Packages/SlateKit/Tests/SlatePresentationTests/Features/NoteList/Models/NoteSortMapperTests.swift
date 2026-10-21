import Foundation
import SlateDomain
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct NoteSortMapperTests {
    @Test func everySortHasATitle() {
        #expect(NoteSort.allCases.map(NoteSortMapper.title(for:)) == ["Date Edited", "Date Created", "Title"])
        #expect(NoteSortMapper.hint(for: .title) == "Sort notes: Title")
    }
}
