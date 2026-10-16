import Foundation
import SlateDomain
import Testing
@testable import SlatePresentation

@Suite struct NoteDragPayloadTests {
    @Test func idRoundTrips() {
        let id = NoteID(rawValue: "abc")

        #expect(NoteDragPayload.noteID(from: NoteDragPayload.text(for: id)) == id)
    }

    @Test func otherTextIsNotANote() {
        #expect(NoteDragPayload.noteID(from: "hello") == nil)
        #expect(NoteDragPayload.noteID(from: NoteDragPayload.prefix) == nil)
    }
}
