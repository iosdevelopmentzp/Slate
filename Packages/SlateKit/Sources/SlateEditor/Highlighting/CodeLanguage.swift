import Foundation

struct CodeLanguage {
    struct Rule {
        let regex: NSRegularExpression
        let kind: CodeTokenKind
        let group: Int

        init(_ pattern: String, _ kind: CodeTokenKind, group: Int = 0, options: NSRegularExpression.Options = []) {
            regex = try! NSRegularExpression(pattern: pattern, options: options)
            self.kind = kind
            self.group = group
        }
    }

    let name: String
    let rules: [Rule]

    static func keywords(_ words: [String]) -> String {
        #"\b(?:"# + words.joined(separator: "|") + #")\b"#
    }
}
