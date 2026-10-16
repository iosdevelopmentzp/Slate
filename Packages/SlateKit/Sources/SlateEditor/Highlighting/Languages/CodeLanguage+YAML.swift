import Foundation

extension CodeLanguage {
    static let yaml = CodeLanguage(name: "yaml", rules: [
        Rule(#"(?:^|\s)#.*$"#, .comment),
        Rule(#""(?:[^"\\]|\\.)*"?|'[^']*'?"#, .string),
        Rule(#"^\s*-?\s*[A-Za-z0-9_.\-/]+(?=\s*:(?:\s|$))"#, .attribute),
        Rule(#"\b(?:true|false|null|yes|no|on|off)\b"#, .keyword),
        Rule(#"(?<![\w.])-?\d+(?:\.\d+)?\b"#, .number),
        Rule(#"^---$|^\.\.\.$"#, .meta),
    ])
}
