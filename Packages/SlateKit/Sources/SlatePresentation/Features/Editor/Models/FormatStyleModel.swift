import SlateEditor

struct FormatStyleModel: Identifiable, Equatable {
    let id: BlockKind
    let title: String
    let shortcut: String
    let isCurrent: Bool
}
