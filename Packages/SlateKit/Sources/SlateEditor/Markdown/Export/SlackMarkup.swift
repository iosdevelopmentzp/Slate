import Foundation
import Markdown

enum SlackMarkup {
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
            "*" + inline(Array(heading.children)) + "*"
        case let paragraph as Paragraph:
            inline(Array(paragraph.children))
        case let code as CodeBlock:
            "```\n" + ExportText.codeText(code) + "\n```"
        case let quote as BlockQuote:
            quoted(quoteParts(quote))
        case let list as UnorderedList:
            listLines(Array(list.listItems), ordered: nil, depth: 0).joined(separator: "\n")
        case let list as OrderedList:
            listLines(Array(list.listItems), ordered: Int(list.startIndex), depth: 0).joined(separator: "\n")
        case let table as Table:
            "```\n" + ExportText.alignedTable(table) + "\n```"
        case is ThematicBreak:
            "———"
        case let html as HTMLBlock:
            html.rawHTML.trimmingCharacters(in: .newlines)
        default:
            markup.format()
        }
    }

    private static func quoteParts(_ quote: BlockQuote) -> [String] {
        guard let callout = ExportCallout(quote) else { return blocks(Array(quote.children)) }
        let title = inline(callout.title).trimmingCharacters(in: .whitespaces)
        var parts = ["*" + (title.isEmpty ? callout.label : title) + "*" + (callout.body.isEmpty ? "" : "\n" + inline(callout.body))]
        parts += blocks(callout.rest)
        return parts
    }

    private static func quoted(_ parts: [String]) -> String {
        parts.joined(separator: "\n\n")
            .components(separatedBy: "\n")
            .map { "> " + $0 }
            .joined(separator: "\n")
    }

    private static func listLines(_ items: [ListItem], ordered start: Int?, depth: Int) -> [String] {
        let indent = String(repeating: "    ", count: depth)
        var lines: [String] = []
        for (offset, item) in items.enumerated() {
            let marker = start.map { "\($0 + offset)." } ?? "•"
            var parts: [String] = []
            var nested: [String] = []
            for child in item.children {
                switch child {
                case let list as UnorderedList:
                    nested += listLines(Array(list.listItems), ordered: nil, depth: depth + 1)
                case let list as OrderedList:
                    nested += listLines(Array(list.listItems), ordered: Int(list.startIndex), depth: depth + 1)
                default:
                    parts.append(block(child))
                }
            }
            lines.append(indent + marker + " " + checkbox(item) + parts.joined(separator: " "))
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

    private static func inline(_ children: [Markup]) -> String {
        var result = ""
        var pending = ""
        for child in children {
            if let text = child as? Text {
                pending += text.string
                continue
            }
            result += ExportText.clean(pending)
            pending = ""
            result += inlineNode(child)
        }
        return result + ExportText.clean(pending)
    }

    private static func inlineNode(_ markup: Markup) -> String {
        switch markup {
        case let strong as Strong:
            "*" + inline(Array(strong.children)) + "*"
        case let emphasis as Emphasis:
            "_" + inline(Array(emphasis.children)) + "_"
        case let strike as Strikethrough:
            "~" + inline(Array(strike.children)) + "~"
        case let code as InlineCode:
            "`" + code.code + "`"
        case let link as Link:
            linkText(link)
        case let image as Image:
            image.source.map(ExportText.imageName) ?? ""
        case is SoftBreak:
            " "
        case is LineBreak:
            "\n"
        case let html as InlineHTML:
            ExportText.isLineBreak(html.rawHTML) ? "\n" : (InlineHTMLTag(html.rawHTML) == nil ? html.rawHTML : "")
        default:
            markup.format()
        }
    }

    private static func linkText(_ link: Link) -> String {
        let label = inline(Array(link.children))
        guard let destination = link.destination, destination.contains("://"), destination.hasPrefix("slate://") == false else {
            return label
        }
        if label.isEmpty || label == destination { return destination }
        return label + " (" + destination + ")"
    }
}
