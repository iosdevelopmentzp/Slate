import SlateDomain
import SlateUI
import Testing
@testable import SlatePresentation

@Suite struct NoteStatusTextTests {
    @Test func titlesUseThePlainWords() {
        #expect(NoteStatus.allCases.map(NoteStatusText.title) == ["To do", "In progress", "In review", "Done", "Dropped"])
    }

    @Test func tintsFollowTheUXRules() {
        #expect(NoteStatus.allCases.map(NoteStatusText.tint) == [.gray, .blue, .orange, .green, .red])
    }
}
