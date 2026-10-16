import Foundation

enum CodeHighlighter {
    static func language(named name: String) -> CodeLanguage {
        switch name.lowercased() {
        case "swift": .swift
        case "objc", "objective-c", "objectivec", "obj-c", "m", "h", "mm": .objectiveC
        case "json", "jsonc": .json
        case "yaml", "yml": .yaml
        case "bash", "sh", "zsh", "shell", "console", "fish": .shell
        case "diff", "patch": .diff
        case "log", "logs", "crash": .log
        default: .plain
        }
    }

    static func tokens(in line: String, language: CodeLanguage) -> [CodeToken] {
        guard language.rules.isEmpty == false, line.isEmpty == false else { return [] }
        let length = (line as NSString).length
        var next: [NSRange?] = Array(repeating: nil, count: language.rules.count)
        var exhausted = Array(repeating: false, count: language.rules.count)
        var tokens: [CodeToken] = []
        var position = 0
        while position < length {
            var best: (index: Int, range: NSRange)?
            for (index, rule) in language.rules.enumerated() where exhausted[index] == false {
                if next[index].map({ $0.location < position }) ?? true {
                    next[index] = firstMatch(of: rule, in: line, from: position, length: length)
                    exhausted[index] = next[index] == nil
                }
                guard let range = next[index] else { continue }
                if range.location < (best?.range.location ?? Int.max) {
                    best = (index, range)
                }
            }
            guard let best else { break }
            tokens.append(CodeToken(range: best.range, kind: language.rules[best.index].kind))
            position = best.range.upperBound
        }
        return tokens
    }

    private static func firstMatch(of rule: CodeLanguage.Rule, in line: String, from position: Int, length: Int) -> NSRange? {
        var start = position
        while start < length {
            guard let match = rule.regex.firstMatch(in: line, options: [.withTransparentBounds, .withoutAnchoringBounds], range: NSRange(location: start, length: length - start)) else { return nil }
            let range = match.range(at: rule.group)
            if range.location != NSNotFound, range.length > 0 { return range }
            start = max(match.range.upperBound, start + 1)
        }
        return nil
    }
}
