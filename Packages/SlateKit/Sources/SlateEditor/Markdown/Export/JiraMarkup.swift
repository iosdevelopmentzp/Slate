import Foundation
import Markdown

enum JiraMarkup {
    private static let special = Set("{}[]|!*_+^~")
    private static let languages: [String: String] = [
        "swift": "swift", "objc": "objc", "objective-c": "objc", "objectivec": "objc",
        "json": "json", "yaml": "yaml", "yml": "yaml", "xml": "xml", "html": "html", "css": "css",
        "bash": "bash", "sh": "bash", "shell": "bash", "zsh": "bash",
        "java": "java", "kotlin": "kotlin", "javascript": "javascript", "js": "javascript", "typescript": "javascript", "ts": "javascript",
        "python": "python", "py": "python", "ruby": "ruby", "go": "go", "sql": "sql", "c": "c", "cpp": "cpp", "c++": "cpp",
    ]

    static func render(_ markdown: String) -> String {
        let document = Document(parsing: markdown, options: [.disableSmartOpts])
        return blocks(Array(document.children)).joined(separator: "\n\n")
    }

    private static func blocks(_ children: [Markup]) -> [String] {
        children.map(block).filter { $0.isEmpty == false }
    }

    private static func block(_ markup: Markup) -> String {
        switch markup {
        case let heading as Heading:
            "h\(heading.level). " + inline(Array(heading.children))
        case let paragraph as Paragraph:
            inline(Array(paragraph.children))
        case let code as CodeBlock:
            codeBlock(code)
        case let quote as BlockQuote:
            "{quote}\n" + blocks(Array(quote.children)).joined(separator: "\n\n") + "\n{quote}"
        case let list as UnorderedList:
            listLines(Array(list.listItems), prefix: "*").joined(separator: "\n")
        case let list as OrderedList:
            listLines(Array(list.listItems), prefix: "#").joined(separator: "\n")
        case let table as Table:
            tableText(table)
        case is ThematicBreak:
            "----"
        case let html as HTMLBlock:
            html.rawHTML.trimmingCharacters(in: .newlines)
        default:
            markup.format()
        }
    }

    private static func codeBlock(_ code: CodeBlock) -> String {
        let text = ExportText.codeText(code)
        guard let language = code.language.flatMap({ languages[$0.lowercased()] }) else {
            return "{noformat}\n" + text + "\n{noformat}"
        }
        return "{code:\(language)}\n" + text + "\n{code}"
    }

    private static func listLines(_ items: [ListItem], prefix: String) -> [String] {
        var lines: [String] = []
        for item in items {
            var line = prefix + " " + checkbox(item)
            var nested: [String] = []
            var parts: [String] = []
            for child in item.children {
                switch child {
                case let list as UnorderedList:
                    nested += listLines(Array(list.listItems), prefix: prefix + "*")
                case let list as OrderedList:
                    nested += listLines(Array(list.listItems), prefix: prefix + "#")
                default:
                    parts.append(block(child))
                }
            }
            line += parts.joined(separator: " \\\\ ")
            lines.append(line)
            lines += nested
        }
        return lines
    }

    private static func checkbox(_ item: ListItem) -> String {
        switch item.checkbox {
        case .checked: "☑ "
        case .unchecked: "☐ "
        case nil: ""
        }
    }

    private static func tableText(_ table: Table) -> String {
        var lines = ["||" + table.head.cells.map { cell($0) + "||" }.joined()]
        for row in table.body.rows {
            lines.append("|" + row.cells.map { cell($0) + "|" }.joined())
        }
        return lines.joined(separator: "\n")
    }

    private static func cell(_ cell: Table.Cell) -> String {
        let text = inline(Array(cell.children)).replacingOccurrences(of: "\n", with: " \\\\ ")
        return text.isEmpty ? " " : text
    }

    private static func inline(_ children: [Markup]) -> String {
        var result = ""
        var pending = ""
        for child in children {
            if let text = child as? Text {
                pending += text.string
                continue
            }
            result += escaped(ExportText.clean(pending))
            pending = ""
            result += inlineNode(child)
        }
        return result + escaped(ExportText.clean(pending))
    }

    private static func inlineNode(_ markup: Markup) -> String {
        switch markup {
        case let strong as Strong:
            "*" + inline(Array(strong.children)) + "*"
        case let emphasis as Emphasis:
            "_" + inline(Array(emphasis.children)) + "_"
        case let strike as Strikethrough:
            "-" + inline(Array(strike.children)) + "-"
        case let code as InlineCode:
            "{{" + code.code + "}}"
        case let link as Link:
            linkText(link)
        case let image as Image:
            imageText(image)
        case is SoftBreak:
            " "
        case is LineBreak:
            "\n"
        case let html as InlineHTML:
            htmlText(html.rawHTML)
        default:
            markup.format()
        }
    }

    private static func linkText(_ link: Link) -> String {
        let label = inline(Array(link.children))
        guard let destination = link.destination, destination.contains("://"), destination.hasPrefix("slate://") == false else {
            return label
        }
        if label.isEmpty || label == escaped(destination) { return "[" + destination + "]" }
        return "[" + label + "|" + destination + "]"
    }

    private static func imageText(_ image: Image) -> String {
        guard let source = image.source, source.isEmpty == false else { return "" }
        let name = ExportText.imageName(source)
        guard let width = ImageSize.width(in: ExportText.altText(image)) else { return "!" + name + "!" }
        return "!" + name + "|width=\(Int(width))!"
    }

    private static func htmlText(_ html: String) -> String {
        if ExportText.isLineBreak(html) { return "\n" }
        switch InlineHTMLTag(html) {
        case .openTextColor(let color): return "{color:\(String(describing: color))}"
        case .closeTextColor: return "{color}"
        case .openHighlight, .closeHighlight: return ""
        case nil: return html
        }
    }

    private static func escaped(_ text: String) -> String {
        let urls = BareURL.ranges(in: text).compactMap { Range($0, in: text) }
        var result = ""
        for index in text.indices {
            let character = text[index]
            if special.contains(character), urls.contains(where: { $0.contains(index) }) == false {
                result += "\\"
            }
            result.append(character)
        }
        return result
    }
}
