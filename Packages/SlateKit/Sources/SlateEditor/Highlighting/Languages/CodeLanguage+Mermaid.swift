import Foundation

extension CodeLanguage {
    static let mermaid = CodeLanguage(name: "mermaid", rules: [
        Rule(#"%%.*$"#, .comment),
        Rule(#""[^"]*"?|\|[^|]*\|"#, .string),
        Rule(keywords([
            "flowchart", "graph", "sequenceDiagram", "classDiagram", "stateDiagram", "stateDiagram-v2", "erDiagram", "gantt", "pie",
            "journey", "gitGraph", "mindmap", "timeline", "quadrantChart", "subgraph", "end", "participant", "actor", "loop", "alt",
            "else", "opt", "par", "and", "critical", "break", "rect", "note", "over", "activate", "deactivate", "title", "section",
            "class", "state", "direction", "dateFormat", "commit", "branch", "checkout", "merge", "TD", "TB", "LR", "RL", "BT",
        ]), .keyword),
        Rule(#"<?[-=.]+[->xo]>?|<?[-=.]{2,}[>xo]?|\|\|--o\{|\}o--\|\|"#, .attribute),
    ])
}
