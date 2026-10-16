import Foundation

package enum ActionEnvironmentPolicy {
    package static func environment(for document: NoteDocument, vault: URL) -> [String: String] {
        let header = document.header
        return [
            "SLATE_VAULT": vault.path,
            "SLATE_NOTE_PATH": vault.appendingPathComponent(document.path.rawValue).path,
            "SLATE_NOTE_TITLE": document.title,
            "SLATE_TICKET": header.ticket ?? "",
            "SLATE_BRANCH": header.branch ?? "",
            "SLATE_MR": header.mr ?? "",
            "SLATE_STATUS": header.status ?? "",
        ]
    }

    package static func logBlock(_ output: String) -> String {
        let text = output.trimmingCharacters(in: .newlines)
        let longest = text.components(separatedBy: "\n").map { line in line.prefix { $0 == "`" }.count }.max() ?? 0
        let ticks = String(repeating: "`", count: max(3, longest + 1))
        return "\(ticks)log\n\(text)\n\(ticks)"
    }
}
