import SlateDomain

struct BacklinkRowModel: Identifiable, Equatable {
    let id: NoteID
    let title: String
    let folder: String
    let context: String

    static let preview = BacklinkRowModel(id: NoteID(rawValue: "a"), title: "ABC-123 Fix login", folder: "Projects / MyApp", context: "The crash comes back in Decisions after the second call.")
}
