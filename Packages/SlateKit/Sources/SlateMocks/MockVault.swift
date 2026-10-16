import Foundation
import SlateDomain

package enum MockVault {
    package static let inbox = SpaceName(rawValue: "Inbox")
    package static let tasks = SpaceName(rawValue: "Tasks")

    package static let reference = Date(timeIntervalSince1970: 1_792_000_000)

    package static let spaces: [Space] = [
        Space(folder: inbox, icon: "tray", noteCount: inboxNotes.count),
        Space(folder: tasks, icon: "checklist", noteCount: taskNotes.count),
    ]

    package static var notes: [NoteSummary] {
        inboxNotes + taskNotes
    }

    package static let inboxNotes: [NoteSummary] = [
        NoteSummary(
            id: NoteID(rawValue: "0b6c1f7e-2a3d-4c5e-8f90-1a2b3c4d5e01"),
            path: VaultPath(rawValue: "Inbox/Welcome to Slate.md"),
            title: "Welcome to Slate",
            pinned: true,
            updated: reference.addingTimeInterval(-120),
            preview: "Notes are plain Markdown files in your notes folder. Press ⌘N for a new note, ⌘F to search, ⌘0 to show the sidebar."
        ),
        NoteSummary(
            id: NoteID(rawValue: "0b6c1f7e-2a3d-4c5e-8f90-1a2b3c4d5e02"),
            path: VaultPath(rawValue: "Inbox/Swift concurrency reading list.md"),
            title: "Swift concurrency reading list",
            updated: reference.addingTimeInterval(-3_600 * 5),
            preview: "Sendable checking, actor reentrancy, task groups and cancellation. Read the evolution proposals first.",
            openTodos: 3
        ),
        NoteSummary(
            id: NoteID(rawValue: "0b6c1f7e-2a3d-4c5e-8f90-1a2b3c4d5e03"),
            path: VaultPath(rawValue: "Inbox/Screenshot of the login screen.md"),
            title: "Screenshot of the login screen",
            updated: reference.addingTimeInterval(-86_400),
            preview: "The button overlaps the keyboard on small screens.",
            attachmentCount: 2
        ),
    ]

    package static let taskNotes: [NoteSummary] = [
        NoteSummary(
            id: NoteID(rawValue: "0b6c1f7e-2a3d-4c5e-8f90-1a2b3c4d5e11"),
            path: VaultPath(rawValue: "Tasks/ABC-123 Fix the crash on launch.md"),
            title: "Fix the crash on launch",
            status: .active,
            ticket: "ABC-123",
            updated: reference.addingTimeInterval(-600),
            preview: "The crash happens when the cache folder is missing. Steps to reproduce, findings and the fix plan.",
            openTodos: 2
        ),
        NoteSummary(
            id: NoteID(rawValue: "0b6c1f7e-2a3d-4c5e-8f90-1a2b3c4d5e12"),
            path: VaultPath(rawValue: "Tasks/ABC-124 Add dark mode to settings.md"),
            title: "Add dark mode to settings",
            status: .review,
            ticket: "ABC-124",
            updated: reference.addingTimeInterval(-86_400 * 2),
            preview: "All colours come from the theme. Check every screen in both appearances.",
            attachmentCount: 1
        ),
        NoteSummary(
            id: NoteID(rawValue: "0b6c1f7e-2a3d-4c5e-8f90-1a2b3c4d5e13"),
            path: VaultPath(rawValue: "Tasks/ABC-120 Update the onboarding text.md"),
            title: "Update the onboarding text",
            status: .done,
            ticket: "ABC-120",
            updated: reference.addingTimeInterval(-86_400 * 9),
            preview: "Shorter sentences on every page. Approved."
        ),
    ]
}
