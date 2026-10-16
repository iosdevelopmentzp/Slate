import SlateEditor

struct FormatButtonModel: Identifiable, Equatable {
    let id: String
    let systemImage: String
    let hint: String
    let command: EditorCommand
    let isActive: Bool
    let isEnabled: Bool

    static let preview = FormatButtonModel(id: "bold", systemImage: "bold", hint: "Bold  ⌘B", command: .inline(.bold), isActive: true, isEnabled: true)
}
