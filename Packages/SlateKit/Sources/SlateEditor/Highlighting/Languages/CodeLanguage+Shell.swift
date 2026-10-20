import Foundation

extension CodeLanguage {
    static let shell = CodeLanguage(name: "bash", rules: [
        Rule(#"(?:^|\s)#.*$"#, .comment),
        Rule(#""(?:[^"\\]|\\.)*"?|'[^']*'?"#, .string),
        Rule(#"\$\{?[A-Za-z_][A-Za-z0-9_]*\}?|\$[0-9@#?*!$-]"#, .attribute),
        Rule(keywords([
            "if", "then", "else", "elif", "fi", "for", "while", "until", "do", "done", "case", "esac", "in", "function",
            "return", "export", "local", "readonly", "set", "unset", "source", "exit", "echo", "cd", "sudo",
        ]), .keyword),
        Rule(#"(?<=\s)--?[A-Za-z0-9][A-Za-z0-9-]*"#, .type),
        Rule(#"\b\d+\b"#, .number),
    ])
}
