import Foundation
import SlateDomain

package enum MockVault {
    package static let inbox = SpaceName(rawValue: "Inbox")
    package static let tasks = SpaceName(rawValue: "Tasks")

    package static let reference = Date(timeIntervalSince1970: 1_792_000_000)

    package static let config = SpacesConfig(spaces: [
        Space(folder: inbox, icon: "tray", defaultType: "note"),
        Space(folder: tasks, icon: "checkmark.circle", defaultType: "task"),
    ])

    package static var spaces: [Space] {
        config.spaces
    }

    package static var notes: [NoteSummary] {
        documents.map { MockIndexedNoteBuilder().build($0).summary }
    }

    package static var inboxNotes: [NoteSummary] {
        notes.filter { $0.space == inbox }
    }

    package static var taskNotes: [NoteSummary] {
        notes.filter { $0.space == tasks }
    }

    package static let documents: [NoteDocument] = [
        document(
            "0b6c1f7e-2a3d-4c5e-8f90-1a2b3c4d5e01", space: inbox, title: "Welcome to Slate", pinned: true, minutesAgo: 2,
            body: "Notes are plain Markdown files in your notes folder.\n\n- ⌘N makes a new note in the current folder.\n- ⌘F searches the notes.\n- ⌘⇧O opens Slate in a window.\n"
        ),
        document(
            "0b6c1f7e-2a3d-4c5e-8f90-1a2b3c4d5e02", space: inbox, title: "Swift concurrency reading list", minutesAgo: 300,
            body: "Sendable checking, actor reentrancy, task groups and cancellation.\n\n- [ ] SE-0306 actors\n- [ ] SE-0304 structured concurrency\n- [ ] SE-0337 incremental migration\n"
        ),
        document(
            "0b6c1f7e-2a3d-4c5e-8f90-1a2b3c4d5e03", space: inbox, title: "Screenshot of the login screen", minutesAgo: 1_440,
            body: "The button overlaps the keyboard on small screens.\n\n![](../_attachments/20261015-101500-screenshot.png)\n![](../_attachments/20261015-101530-screenshot.png)\n"
        ),
        document(
            "0b6c1f7e-2a3d-4c5e-8f90-1a2b3c4d5e11", space: tasks, title: "ABC-123 Fix the crash on launch", type: .task, status: .active, ticket: "ABC-123", minutesAgo: 10,
            body: "## Context\n\nThe crash happens when the cache folder is missing.\n\n## Plan\n\n- [x] Reproduce\n- [ ] Create the folder on launch\n- [ ] Add a test\n"
        ),
        document(
            "0b6c1f7e-2a3d-4c5e-8f90-1a2b3c4d5e12", space: tasks, title: "ABC-124 Add dark mode to settings", type: .task, status: .review, ticket: "ABC-124", minutesAgo: 2_880,
            body: "## Context\n\nAll colours come from the theme. Check every screen in both appearances.\n\n![](../_attachments/20261014-090000-window.png)\n"
        ),
        document(
            "0b6c1f7e-2a3d-4c5e-8f90-1a2b3c4d5e13", space: tasks, title: "ABC-120 Update the onboarding text", type: .task, status: .done, ticket: "ABC-120", minutesAgo: 12_960,
            body: "## Context\n\nShorter sentences on every page. Approved.\n"
        ),
    ]

    private static func document(
        _ id: String,
        space: SpaceName,
        title: String,
        type: NoteType = .note,
        status: NoteStatus? = nil,
        ticket: String? = nil,
        pinned: Bool = false,
        minutesAgo: Double,
        body: String
    ) -> NoteDocument {
        let date = reference.addingTimeInterval(-minutesAgo * 60)
        var header = HeaderDefaultsPolicy.header(id: NoteID(rawValue: id), title: title, type: type, now: date)
        header.status = status?.rawValue
        header.ticket = ticket
        header.pinned = pinned ? true : nil
        let path = VaultPath(space: space, stem: StemPolicy.stem(forTitle: title))
        let data = NoteCodec.encode(header: header, body: body, opaqueHeader: nil, timeZone: .gmt)
        return NoteDocument(
            path: path,
            header: header,
            body: body,
            hash: .of(data),
            meta: FileMeta(path: path, created: date, modified: date, size: data.count)
        )
    }
}
