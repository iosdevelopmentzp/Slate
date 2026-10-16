import SlateDomain
import Testing
@testable import SlatePresentation

@Suite struct AppEventTests {
    @Test func eventsCompareByCaseAndPayload() {
        let id = NoteID(rawValue: "a")

        #expect(AppEvent.noteSaved(id) == .noteSaved(id))
        #expect(AppEvent.noteSaved(id) != .noteCreated(id, caret: 0))
        #expect(AppEvent.noteCreated(id, caret: 1) != .noteCreated(id, caret: 2))
    }
}
