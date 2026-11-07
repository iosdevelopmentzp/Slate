import AppKit

extension RichTextController {

    func copy(for format: ExportFormat, to pasteboard: NSPasteboard = PasteboardBridge.general) {
        activeTable?.commit()
        let selection = textView.selectedRange()
        let source = selection.length > 0 ? storage.attributedSubstring(from: selection) : storage
        let markdown = MarkdownWriter.write(source)
        pasteboard.clearContents()
        switch format {
        case .jira:
            pasteboard.setString(JiraMarkup.render(markdown), forType: .string)
        case .slack:
            pasteboard.declareTypes([.html, .string], owner: nil)
            pasteboard.setString(SlackHTML.render(markdown), forType: .html)
            pasteboard.setString(SlackMarkup.render(markdown), forType: .string)
        }
        handlers.notice(format.notice)
    }

    func addExportItems(to menu: NSMenu) {
        let copyIndex = menu.items.firstIndex { $0.action == #selector(NSText.copy(_:)) }
        var index = copyIndex.map { $0 + 1 } ?? menu.items.count
        for (title, action) in [("Copy for Jira", EditorMenuActions.copyForJira), ("Copy for Slack", EditorMenuActions.copyForSlack)] {
            let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
            item.target = textView
            menu.insertItem(item, at: index)
            index += 1
        }
    }
}
