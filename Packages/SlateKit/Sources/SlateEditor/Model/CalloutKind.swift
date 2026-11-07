import AppKit

nonisolated enum CalloutKind: String, CaseIterable {
    case note
    case info
    case tip
    case important
    case success
    case question
    case answer
    case warning
    case caution
    case danger
    case bug
    case example
    case todo
    case abstract
    case failure

    private static let aliases: [String: CalloutKind] = [
        "summary": .abstract, "tldr": .abstract, "hint": .tip, "check": .success, "done": .success,
        "help": .question, "faq": .question, "attention": .warning, "error": .danger, "fail": .failure, "missing": .failure,
    ]

    static let menuKinds: [CalloutKind] = [.note, .tip, .important, .warning, .question]

    init(marker: String) {
        let name = marker.trimmingCharacters(in: CharacterSet(charactersIn: "+-")).lowercased()
        self = CalloutKind(rawValue: name) ?? Self.aliases[name] ?? .note
    }

    var marker: String {
        rawValue.uppercased()
    }

    var title: String {
        rawValue.prefix(1).uppercased() + rawValue.dropFirst()
    }

    var symbol: String {
        switch self {
        case .note: "pencil.circle.fill"
        case .info: "info.circle.fill"
        case .tip: "lightbulb.fill"
        case .important: "exclamationmark.bubble.fill"
        case .success: "checkmark.circle.fill"
        case .question: "questionmark.circle.fill"
        case .answer: "checkmark.bubble.fill"
        case .warning, .caution: "exclamationmark.triangle.fill"
        case .danger: "bolt.fill"
        case .bug: "ladybug.fill"
        case .example: "list.bullet.rectangle.fill"
        case .todo: "checklist"
        case .abstract: "doc.text.fill"
        case .failure: "xmark.circle.fill"
        }
    }

    var color: NSColor {
        switch self {
        case .note, .info, .abstract: .systemBlue
        case .tip, .success, .answer: .systemGreen
        case .important, .example: .systemPurple
        case .question, .todo: .systemTeal
        case .warning: .systemOrange
        case .caution, .danger, .bug, .failure: .systemRed
        }
    }

    static func label(for marker: String) -> String {
        let name = marker.trimmingCharacters(in: CharacterSet(charactersIn: "+-")).lowercased()
        if CalloutKind(rawValue: name) != nil || aliases[name] != nil { return CalloutKind(marker: marker).title }
        return name.prefix(1).uppercased() + name.dropFirst()
    }
}
