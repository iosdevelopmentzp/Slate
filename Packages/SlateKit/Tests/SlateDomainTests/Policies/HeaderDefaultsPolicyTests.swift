import Foundation
import Testing
@testable import SlateDomain

@Suite struct HeaderDefaultsPolicyTests {
    @Test func taskHeaderStartsAsTodo() {
        let now = Date(timeIntervalSince1970: 100)

        let header = HeaderDefaultsPolicy.header(id: NoteID(rawValue: "x"), title: "T", type: .task, now: now)

        #expect(header == NoteHeader(id: NoteID(rawValue: "x"), title: "T", type: "task", created: now, updated: now, status: "todo"))
    }

    @Test func plainNoteHasNoStatus() {
        let header = HeaderDefaultsPolicy.header(id: NoteID(rawValue: "x"), title: "T", type: .note, now: .now)

        #expect(header.status == nil)
    }

    @Test func typeComesFromTheRequestThenTheSpace() {
        let tasks = Space(folder: SpaceName(rawValue: "Tasks"), defaultType: "task")

        #expect(HeaderDefaultsPolicy.type(named: "meeting", space: tasks, among: NoteType.builtIn).name == "meeting")
        #expect(HeaderDefaultsPolicy.type(named: nil, space: tasks, among: NoteType.builtIn).name == "task")
        #expect(HeaderDefaultsPolicy.type(named: nil, space: nil, among: NoteType.builtIn).name == "note")
        #expect(HeaderDefaultsPolicy.type(named: "unknown", space: nil, among: NoteType.builtIn).name == "note")
    }

    @Test func spaceComesFromTheRequestThenTheTypeThenCapture() {
        let config = SpacesConfig.sixFolders
        let notes = SpaceName(rawValue: "Notes")

        #expect(HeaderDefaultsPolicy.space(for: .task, requested: notes, config: config) == notes)
        #expect(HeaderDefaultsPolicy.space(for: .task, requested: nil, config: config) == SpaceName(rawValue: "Tasks"))
        #expect(HeaderDefaultsPolicy.space(for: .note, requested: nil, config: config) == SpaceName(rawValue: "Inbox"))
        #expect(HeaderDefaultsPolicy.space(for: .task, requested: nil, config: SpacesConfig(spaces: [])) == SpaceName(rawValue: "Notes"))
    }
}
