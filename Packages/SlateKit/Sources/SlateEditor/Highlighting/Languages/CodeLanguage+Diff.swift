import Foundation

extension CodeLanguage {
    static let diff = CodeLanguage(name: "diff", rules: [
        Rule(#"^(?:\+\+\+|---)\s.*$"#, .meta),
        Rule(#"^@@.*$"#, .meta),
        Rule(#"^diff\s.*$|^index\s.*$"#, .meta),
        Rule(#"^\+.*$"#, .added),
        Rule(#"^-.*$"#, .removed),
    ])
}
