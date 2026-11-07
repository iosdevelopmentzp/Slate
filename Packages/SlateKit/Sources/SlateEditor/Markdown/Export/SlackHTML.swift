import Foundation
import Markdown

enum SlackHTML {
    static func render(_ markdown: String) -> String {
        let document = Document(parsing: markdown, options: [.disableSmartOpts])
        return Array(document.children).map(block).joined()
    }

    private static func block(_ markup: Markup) -> String {
        switch markup {
        case let heading as Heading:
            "<p><b>" + inline(Array(heading.children)) + "</b></p>"
        case let paragraph as Paragraph:
            "<p>" + inline(Array(paragraph.children)) + "</p>"
        case let code as CodeBlock:
            "<pre>" + escaped(ExportText.codeText(code)) + "</pre>"
        case let quote as BlockQuote:
            "<blockquote>" + quoteBody(quote) + "</blockquote>"
        case let list as UnorderedList:
            "<ul>" + Array(list.listItems).map(item).joined() + "</ul>"
        case let list as OrderedList:
            "<ol start=\"\(list.startIndex)\">" + Array(list.listItems).map(item).joined() + "</ol>"
        case let table as Table:
            "<pre>" + escaped(ExportText.alignedTable(table)) + "</pre>"
        case is ThematicBreak:
            "<hr>"
        case let html as HTMLBlock:
            "<p>" + escaped(html.rawHTML.trimmingCharacters(in: .newlines)) + "</p>"
        default:
            "<p>" + escaped(markup.format()) + "</p>"
        }
    }

    private static func quoteBody(_ quote: BlockQuote) -> String {
        guard let callout = ExportCallout(quote) else { return Array(quote.children).map(block).joined() }
        let title = inline(callout.title).trimmingCharacters(in: .whitespaces)
        var html = "<p><b>" + (title.isEmpty ? escaped(callout.label) : title) + "</b></p>"
        if callout.body.isEmpty == false { html += "<p>" + inline(callout.body) + "</p>" }
        return html + callout.rest.map(block).joined()
    }

    private static func item(_ item: ListItem) -> String {
        var text = checkbox(item)
        for child in item.children {
            if let paragraph = child as? Paragraph {
                text += inline(Array(paragraph.children))
            } else {
                text += block(child)
            }
        }
        return "<li>" + text + "</li>"
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
            result += escaped(ExportText.clean(pending))
            pending = ""
            result += inlineNode(child)
        }
        return result + escaped(ExportText.clean(pending))
    }

    private static func inlineNode(_ markup: Markup) -> String {
        switch markup {
        case let strong as Strong:
            "<b>" + inline(Array(strong.children)) + "</b>"
        case let emphasis as Emphasis:
            "<i>" + inline(Array(emphasis.children)) + "</i>"
        case let strike as Strikethrough:
            "<s>" + inline(Array(strike.children)) + "</s>"
        case let code as InlineCode:
            "<code>" + escaped(code.code) + "</code>"
        case let link as Link:
            linkText(link)
        case let image as Image:
            escaped(image.source.map(ExportText.imageName) ?? "")
        case is SoftBreak:
            " "
        case is LineBreak:
            "<br>"
        case let html as InlineHTML:
            ExportText.isLineBreak(html.rawHTML) ? "<br>" : (InlineHTMLTag(html.rawHTML) == nil ? escaped(html.rawHTML) : "")
        default:
            escaped(markup.format())
        }
    }

    private static func linkText(_ link: Link) -> String {
        let label = inline(Array(link.children))
        guard let destination = link.destination, destination.contains("://"), destination.hasPrefix("slate://") == false else {
            return label
        }
        return "<a href=\"" + escaped(destination) + "\">" + (label.isEmpty ? escaped(destination) : label) + "</a>"
    }

    private static func escaped(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
