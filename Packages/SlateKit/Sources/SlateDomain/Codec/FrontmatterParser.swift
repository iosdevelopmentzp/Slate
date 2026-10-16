import Foundation

package enum FrontmatterParser {
    package struct Result: Hashable, Sendable {
        package var header: NoteHeader
        package var body: String
        package var hasHeader: Bool
        package var opaqueHeader: String?

        package init(header: NoteHeader, body: String, hasHeader: Bool, opaqueHeader: String?) {
            self.header = header
            self.body = body
            self.hasHeader = hasHeader
            self.opaqueHeader = opaqueHeader
        }
    }

    static let delimiter = "---"

    package static func parse(_ text: String) -> Result {
        guard let block = headerBlock(in: text) else {
            return Result(header: NoteHeader(), body: text, hasHeader: false, opaqueHeader: nil)
        }
        var header = NoteHeader()
        var isOpaque = false
        for line in block.lines {
            switch classify(line) {
            case .skip:
                continue
            case .opaque:
                isOpaque = true
            case .entry(let key, let value):
                if apply(key: key, value: value, to: &header) == false {
                    if unsupported(value) {
                        isOpaque = true
                    }
                    header.unknownLines.append(line)
                }
            }
        }
        return Result(header: header, body: block.body, hasHeader: true, opaqueHeader: isOpaque ? block.raw : nil)
    }

    private struct Block {
        let raw: String
        let lines: [String]
        let body: String
    }

    private static func headerBlock(in text: String) -> Block? {
        let lines = text.components(separatedBy: "\n")
        guard lines.count > 1, stripCarriageReturn(lines[0]) == delimiter else { return nil }
        guard let end = lines.indices.dropFirst().first(where: { stripCarriageReturn(lines[$0]) == delimiter }) else { return nil }
        let headerLines = lines[1..<end].map(stripCarriageReturn)
        let rawLines = lines[0...end]
        let hasBody = end + 1 < lines.count
        let raw = rawLines.joined(separator: "\n") + (hasBody ? "\n" : "")
        let body = hasBody ? lines[(end + 1)...].joined(separator: "\n") : ""
        return Block(raw: raw, lines: headerLines, body: body)
    }

    private static func stripCarriageReturn(_ line: String) -> String {
        line.hasSuffix("\r") ? String(line.dropLast()) : line
    }

    private enum LineKind {
        case skip
        case opaque
        case entry(key: String, value: String?)
    }

    private static func classify(_ line: String) -> LineKind {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty || trimmed.hasPrefix("#") {
            return .skip
        }
        guard let colon = line.firstIndex(of: ":") else { return .opaque }
        let key = String(line[..<colon])
        guard isValidKey(key) else { return .opaque }
        let rest = line[line.index(after: colon)...]
        if rest.isEmpty || rest.allSatisfy(\.isWhitespace) {
            return .entry(key: key, value: nil)
        }
        guard rest.first == " " else { return .opaque }
        return .entry(key: key, value: rest.trimmingCharacters(in: .whitespaces))
    }

    private static func isValidKey(_ key: String) -> Bool {
        guard let first = key.unicodeScalars.first, ("a"..."z").contains(first) else { return false }
        return key.unicodeScalars.allSatisfy { ("a"..."z").contains($0) || ("0"..."9").contains($0) || $0 == "_" || $0 == "-" }
    }

    private static func unsupported(_ value: String?) -> Bool {
        guard let first = value?.first else { return false }
        return "&*!|>{%@`".contains(first)
    }

    private static func apply(key: String, value: String?, to header: inout NoteHeader) -> Bool {
        guard NoteHeader.knownKeys.contains(key) else { return false }
        if unsupported(value) { return false }
        switch key {
        case "id":
            guard let text = string(value) else { return value == nil }
            header.id = NoteID(rawValue: text)
        case "title":
            header.title = string(value)
        case "type":
            header.type = string(value)
        case "created":
            guard let date = date(value) else { return value == nil }
            header.created = date
        case "updated":
            guard let date = date(value) else { return value == nil }
            header.updated = date
        case "tags":
            guard let list = list(value) else { return value == nil }
            header.tags = list
        case "aliases":
            guard let list = list(value) else { return value == nil }
            header.aliases = list
        case "pinned":
            guard let flag = bool(value) else { return value == nil }
            header.pinned = flag
        case "ticket":
            header.ticket = string(value)
        case "branch":
            header.branch = string(value)
        case "mr":
            header.mr = string(value)
        case "status":
            header.status = string(value)
        case "language":
            header.language = string(value)
        case "due":
            header.due = string(value)
        default:
            return false
        }
        return true
    }

    static func string(_ value: String?) -> String? {
        guard let value else { return nil }
        if let quoted = unquote(value) {
            return quoted
        }
        return value
    }

    private static func unquote(_ value: String) -> String? {
        if value.count >= 2, value.hasPrefix("\""), value.hasSuffix("\"") {
            var result = ""
            var escaping = false
            for character in value.dropFirst().dropLast() {
                if escaping {
                    result.append(character)
                    escaping = false
                } else if character == "\\" {
                    escaping = true
                } else {
                    result.append(character)
                }
            }
            return result
        }
        if value.count >= 2, value.hasPrefix("'"), value.hasSuffix("'") {
            return String(value.dropFirst().dropLast()).replacingOccurrences(of: "''", with: "'")
        }
        return nil
    }

    private static func bool(_ value: String?) -> Bool? {
        switch value {
        case "true": true
        case "false": false
        default: nil
        }
    }

    private static func date(_ value: String?) -> Date? {
        guard let text = string(value) else { return nil }
        return try? Date(text, strategy: .iso8601)
    }

    private static func list(_ value: String?) -> [String]? {
        guard let value, value.hasPrefix("["), value.hasSuffix("]") else { return nil }
        let inner = value.dropFirst().dropLast()
        var items: [String] = []
        var current = ""
        var quote: Character?
        var escaping = false
        for character in inner {
            if escaping {
                current.append(character)
                escaping = false
                continue
            }
            if let open = quote {
                current.append(character)
                if character == "\\", open == "\"" {
                    escaping = true
                } else if character == open {
                    quote = nil
                }
                continue
            }
            if character == "\"" || character == "'" {
                quote = character
                current.append(character)
            } else if character == "," {
                items.append(current)
                current = ""
            } else if character == "[" || character == "]" || character == "{" {
                return nil
            } else {
                current.append(character)
            }
        }
        guard quote == nil else { return nil }
        items.append(current)
        let trimmed = items.map { $0.trimmingCharacters(in: .whitespaces) }
        if trimmed == [""] {
            return []
        }
        guard trimmed.contains("") == false else { return nil }
        return trimmed.compactMap { string($0) }
    }
}
