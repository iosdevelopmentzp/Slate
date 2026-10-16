import Foundation

extension CodeLanguage {
    static let swift = CodeLanguage(name: "swift", rules: [
        Rule(#"//.*$"#, .comment),
        Rule(#"/\*.*?(?:\*/|$)"#, .comment),
        Rule(#""(?:[^"\\]|\\.)*"?"#, .string),
        Rule(#"@\w+"#, .attribute),
        Rule(keywords([
            "actor", "as", "associatedtype", "async", "await", "break", "case", "catch", "class", "continue", "default", "defer",
            "deinit", "do", "else", "enum", "extension", "fallthrough", "false", "fileprivate", "final", "for", "func", "guard",
            "if", "import", "in", "init", "inout", "internal", "is", "lazy", "let", "mutating", "nil", "nonisolated", "open",
            "override", "package", "private", "protocol", "public", "repeat", "rethrows", "return", "self", "Self", "some",
            "static", "struct", "subscript", "super", "switch", "throw", "throws", "true", "try", "typealias", "unowned", "var",
            "weak", "where", "while", "any",
        ]), .keyword),
        Rule(#"\b[A-Z][A-Za-z0-9_]*\b"#, .type),
        Rule(#"\b(?:0x[0-9A-Fa-f_]+|\d[\d_]*(?:\.\d+)?)\b"#, .number),
    ])
}
