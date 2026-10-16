import Foundation
import SlateDomain

enum NoteSummaryFixture {
    static let now = Date(timeIntervalSince1970: 1_800_000_000)

    static func note(
        _ id: String,
        path: String,
        title: String? = nil,
        pinned: Bool = false,
        minutesAgo: Double = 0,
        status: NoteStatus? = nil,
        ticket: String? = nil,
        openTodos: Int = 0,
        attachmentCount: Int = 0
    ) -> NoteSummary {
        NoteSummary(
            id: NoteID(rawValue: id),
            path: VaultPath(rawValue: path),
            title: title ?? VaultPath(rawValue: path).stem,
            status: status,
            ticket: ticket,
            pinned: pinned,
            updated: now.addingTimeInterval(-minutesAgo * 60),
            preview: "Preview of \(id)",
            openTodos: openTodos,
            attachmentCount: attachmentCount
        )
    }

    static let inbox = SpaceName(rawValue: "Inbox")
    static let tasks = SpaceName(rawValue: "Tasks")

    static let spaces = [Space(folder: inbox, noteCount: 2), Space(folder: tasks, noteCount: 2)]

    static let notes = [
        note("a", path: "Inbox/Old idea.md", minutesAgo: 60),
        note("b", path: "Inbox/Welcome.md", pinned: true, minutesAgo: 600),
        note("c", path: "Tasks/Fix the crash.md", minutesAgo: 5, status: .active, ticket: "ABC-123"),
        note("d", path: "Tasks/Update the text.md", minutesAgo: 30, status: .done, ticket: "ABC-120"),
    ]
}
