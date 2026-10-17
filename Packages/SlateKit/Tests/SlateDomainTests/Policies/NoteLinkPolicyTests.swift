import Foundation
import Testing
@testable import SlateDomain

@Suite struct NoteLinkPolicyTests {
    @Test func theLinkOpensTheNoteByID() {
        #expect(NoteLinkPolicy.openLink(for: NoteID(rawValue: "9b1deb4d"))?.absoluteString == "slate://open?id=9b1deb4d")
        #expect(NoteLinkPolicy.openLink(for: NoteID(rawValue: "path:Notes/A b.md"))?.absoluteString == "slate://open?id=path:Notes/A%20b.md")
    }
}
