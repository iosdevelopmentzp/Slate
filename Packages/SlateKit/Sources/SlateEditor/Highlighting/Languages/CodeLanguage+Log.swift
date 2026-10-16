import Foundation

extension CodeLanguage {
    static let log = CodeLanguage(name: "log", rules: [
        Rule(#"\b\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}(?:[.,]\d+)?(?:Z|[+-]\d{2}:?\d{2})?|\b\d{2}:\d{2}:\d{2}(?:\.\d+)?\b"#, .number),
        Rule(#"\b(?:ERROR|FATAL|CRITICAL|FAULT|error|fatal|fault|Crashed)\b"#, .removed),
        Rule(#"\b(?:WARN|WARNING|warning|warn)\b"#, .attribute),
        Rule(#"\b(?:INFO|DEBUG|TRACE|NOTICE|info|debug|trace|notice)\b"#, .keyword),
        Rule(#""(?:[^"\\]|\\.)*""#, .string),
    ])
}
