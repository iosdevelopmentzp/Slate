import Foundation

extension CodeLanguage {
    static let json = CodeLanguage(name: "json", rules: [
        Rule(#""(?:[^"\\]|\\.)*"(?=\s*:)"#, .attribute),
        Rule(#""(?:[^"\\]|\\.)*"?"#, .string),
        Rule(#"\b(?:true|false|null)\b"#, .keyword),
        Rule(#"-?\b\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\b"#, .number),
    ])
}
