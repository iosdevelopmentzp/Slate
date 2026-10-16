import Foundation

extension CodeLanguage {
    static let objectiveC = CodeLanguage(name: "objc", rules: [
        Rule(#"//.*$"#, .comment),
        Rule(#"/\*.*?(?:\*/|$)"#, .comment),
        Rule(#"@?"(?:[^"\\]|\\.)*"?"#, .string),
        Rule(#"^\s*#\s*\w+"#, .meta),
        Rule(#"@\w+"#, .keyword),
        Rule(keywords([
            "auto", "break", "case", "char", "const", "continue", "default", "do", "double", "else", "enum", "extern", "float",
            "for", "goto", "if", "inline", "int", "long", "register", "return", "short", "signed", "sizeof", "static", "struct",
            "switch", "typedef", "union", "unsigned", "void", "volatile", "while", "self", "super", "nil", "Nil", "YES", "NO",
            "id", "instancetype", "nonatomic", "strong", "weak", "assign", "copy", "readonly", "readwrite", "nullable", "nonnull",
            "BOOL", "NULL",
        ]), .keyword),
        Rule(#"\b[A-Z][A-Za-z0-9_]*\b"#, .type),
        Rule(#"\b(?:0x[0-9A-Fa-f]+|\d+(?:\.\d+)?[fFlLuU]*)\b"#, .number),
    ])
}
