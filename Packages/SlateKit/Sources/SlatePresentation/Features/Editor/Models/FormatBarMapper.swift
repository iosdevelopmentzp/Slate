import SlateEditor

enum FormatBarMapper {
    static let styleKinds: [BlockKind] = [.title, .heading, .subheading, .body, .monospaced]

    static func styleName(for state: EditorStyleState) -> String {
        switch state.kind {
        case .title: "Title"
        case .heading: "Heading"
        case .subheading: "Subheading"
        case .monospaced, .raw: "Code block"
        case .checklist: "Checklist"
        case .bullet: "Bulleted list"
        case .numbered: "Numbered list"
        case .quote: "Quote"
        case .image: "Image"
        case .divider: "Divider"
        case .table: "Table"
        case .body: "Body"
        }
    }

    static func styles(for state: EditorStyleState) -> [FormatStyleModel] {
        styleKinds.map { kind in
            FormatStyleModel(id: kind, title: title(for: kind), shortcut: shortcut(for: kind), isCurrent: state.kind == kind)
        }
    }

    static func textButtons(for state: EditorStyleState) -> [FormatButtonModel] {
        [
            inline(.bold, id: "bold", image: "bold", hint: "Bold  ⌘B", state: state),
            inline(.italic, id: "italic", image: "italic", hint: "Italic  ⌘I", state: state),
            inline(.strikethrough, id: "strikethrough", image: "strikethrough", hint: "Strikethrough  ⇧⌘X", state: state),
        ]
    }

    static func blockButtons(for state: EditorStyleState) -> [FormatButtonModel] {
        [
            block(.checklist, id: "checklist", image: "checklist", hint: "Checklist  ⇧⌘L", state: state),
            block(.bullet, id: "bulleted", image: "list.bullet", hint: "Bulleted list  ⇧⌘7", state: state),
            block(.numbered, id: "numbered", image: "list.number", hint: "Numbered list  ⇧⌘9", state: state),
            FormatButtonModel(id: "quote", systemImage: "text.quote", hint: "Quote  ⌘'", command: .quote, isActive: state.kind == .quote, isEnabled: state.canFormatText),
            FormatButtonModel(id: "code", systemImage: "chevron.left.forwardslash.chevron.right", hint: "Code block  ⇧⌘M", command: .list(.monospaced), isActive: state.kind == .monospaced, isEnabled: state.canFormatText || state.kind == .monospaced),
            FormatButtonModel(id: "link", systemImage: "link", hint: "Link  ⌘K", command: .link, isActive: state.isLink, isEnabled: state.canFormatText),
            FormatButtonModel(id: "image", systemImage: "photo", hint: "Image  ⇧⌘I", command: .image, isActive: false, isEnabled: true),
            FormatButtonModel(id: "file", systemImage: "paperclip", hint: "Attach file  ⇧⌘A", command: .file, isActive: false, isEnabled: true),
            FormatButtonModel(id: "table", systemImage: "tablecells", hint: "Table  ⌥⌘T", command: .table, isActive: state.kind == .table, isEnabled: true),
        ]
    }

    static func moreButtons(for state: EditorStyleState) -> [FormatButtonModel] {
        [
            FormatButtonModel(id: "divider", systemImage: "minus", hint: "Divider", command: .divider, isActive: false, isEnabled: true),
            FormatButtonModel(id: "screenshot", systemImage: "camera.viewfinder", hint: "Screenshot  ⇧⌘S", command: .screenshot, isActive: false, isEnabled: true),
            FormatButtonModel(id: "formatJSON", systemImage: "curlybraces", hint: "Format JSON  ⌥⇧⌘J", command: .formatJSON, isActive: false, isEnabled: true),
        ]
    }

    private static func title(for kind: BlockKind) -> String {
        styleName(for: EditorStyleState(kind: kind))
    }

    private static func shortcut(for kind: BlockKind) -> String {
        switch kind {
        case .title: "⇧⌘T"
        case .heading: "⇧⌘H"
        case .subheading: "⇧⌘J"
        case .monospaced: "⇧⌘M"
        default: "⇧⌘B"
        }
    }

    private static func inline(_ style: InlineStyle, id: String, image: String, hint: String, state: EditorStyleState) -> FormatButtonModel {
        FormatButtonModel(id: id, systemImage: image, hint: hint, command: .inline(style), isActive: state.inline.contains(style), isEnabled: state.canFormatText)
    }

    private static func block(_ kind: BlockKind, id: String, image: String, hint: String, state: EditorStyleState) -> FormatButtonModel {
        FormatButtonModel(id: id, systemImage: image, hint: hint, command: .list(kind), isActive: state.kind == kind, isEnabled: state.canFormatText)
    }
}
