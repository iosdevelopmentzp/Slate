import Foundation

extension NoteType {
    package static let note = NoteType(name: "note", title: "Note", icon: "note.text")

    package static let task = NoteType(
        name: "task",
        title: "Task",
        icon: "checkmark.circle",
        defaultSpace: SpaceName(rawValue: "Tasks"),
        fields: ["ticket", "branch", "mr", "status"],
        titlePattern: "{{ticket}} {{title}}",
        branchPattern: "feature/{{ticket}}-{{slug}}",
        statuses: NoteStatus.allCases.map(\.rawValue),
        doneStatuses: [NoteStatus.done.rawValue, NoteStatus.dropped.rawValue]
    )

    package static let daily = NoteType(name: "daily", title: "Daily", icon: "calendar", defaultSpace: SpaceName(rawValue: "Daily"))

    package static let snippet = NoteType(
        name: "snippet",
        title: "Snippet",
        icon: "chevron.left.forwardslash.chevron.right",
        defaultSpace: SpaceName(rawValue: "Snippets"),
        fields: ["language"]
    )

    package static let meeting = NoteType(name: "meeting", title: "Meeting", icon: "person.2", defaultSpace: SpaceName(rawValue: "Notes"))

    package static let builtIn: [NoteType] = [.note, .task, .daily, .snippet, .meeting]
}
