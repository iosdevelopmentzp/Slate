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

    static let choices: [CodeLanguage] = [.swift, .objectiveC, .json, .yaml, .shell, .diff, .log]

    var title: String {
        switch name {
        case "swift": "Swift"
        case "objc": "Objective-C"
        case "json": "JSON"
        case "yaml": "YAML"
        case "bash": "Shell"
        case "diff": "Diff"
        case "log": "Log"
        default: "Plain text"
        }
    }

    static func label(for fence: String?) -> String {
        guard let fence, fence.isEmpty == false else { return CodeLanguage.plain.title }
        let language = CodeHighlighter.language(named: fence)
        return language.name == CodeLanguage.plain.name ? fence : language.title
    }

    static func keywords(_ words: [String]) -> String {
        #"\b(?:"# + words.joined(separator: "|") + #")\b"#
    }
}
