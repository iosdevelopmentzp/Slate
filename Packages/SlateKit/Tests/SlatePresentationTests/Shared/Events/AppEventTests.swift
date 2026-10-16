import SlateDomain
import Testing
@testable import SlatePresentation

@Suite struct AppEventTests {
    @Test func eventsCompareByCaseAndPayload() {
        let id = NoteID(rawValue: "a")

        #expect(AppEvent.noteSaved(id) == .noteSaved(id))
        #expect(AppEvent.noteSaved(id) != .noteCreated(id))
    }
}
