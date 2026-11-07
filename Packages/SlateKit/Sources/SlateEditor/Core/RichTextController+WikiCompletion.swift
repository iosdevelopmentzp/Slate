import AppKit

extension RichTextController {

    func updateWikiCompletion() {
        guard let open = openWikiQuery() else {
            hideWikiCompletion()
            return
        }
        guard let names = wikiNames else {
            loadWikiNames()
            return
        }
        guard let window = textView.window else { return }
        let screen = textView.firstRect(forCharacterRange: NSRange(location: open.start, length: 0), actualRange: nil)
        let caret = textView.convert(window.convertFromScreen(screen), from: nil)
        suggestionList.show(NoteSuggestion.matches(for: open.query, in: names), below: caret, in: textView)
    }

    func hideWikiCompletion() {
        suggestionList.hide()
        wikiNames = nil
    }

    func handleWikiCompletion(_ selector: Selector) -> Bool {
        guard suggestionList.isHidden == false else { return false }
        switch selector {
        case #selector(NSResponder.moveUp(_:)):
            suggestionList.moveSelection(by: -1)
        case #selector(NSResponder.moveDown(_:)):
            suggestionList.moveSelection(by: 1)
        case #selector(NSResponder.insertNewline(_:)), #selector(NSResponder.insertTab(_:)):
            guard let suggestion = suggestionList.selectedSuggestion else { return false }
            pickWikiSuggestion(suggestion)
        case #selector(NSResponder.cancelOperation(_:)):
            suggestionList.hide()
        default:
            return false
        }
        return true
    }

    func pickWikiSuggestion(_ suggestion: NoteSuggestion) {
        guard let open = openWikiQuery() else { return }
        let caret = textView.selectedRange().location
        var end = caret
        if end + 2 <= storage.length, string.substring(with: NSRange(location: end, length: 2)) == "]]" {
            end += 2
        }
        insertWikiLink(target: suggestion.name, label: suggestion.name, replacing: NSRange(location: open.start, length: end - open.start))
        hideWikiCompletion()
    }

    func convertClosedWikilink() {
        let selection = textView.selectedRange()
        guard selection.length == 0, multiCaret.isActive == false, let head = textBeforeCaret(), let closed = WikiQuery.closed(before: head.text) else { return }
        let range = NSRange(location: head.location + closed.range.location, length: closed.range.length)
        guard isPlainText(range) else { return }
        insertWikiLink(target: closed.target, label: closed.label, replacing: range)
        hideWikiCompletion()
    }

    private func insertWikiLink(target: String, label: String, replacing range: NSRange) {
        let inline = range.location < storage.length ? InlineStyle(rawValue: storage.attribute(.slateInline, at: range.location, effectiveRange: nil) as? Int ?? 0) : []
        let link = NSAttributedString(string: label, attributes: styler.attributes(block: currentBlock, inline: inline, href: RichText.wikiPrefix + target))
        replace(range, with: link, selection: NSRange(location: range.location + link.length, length: 0))
    }

    private func openWikiQuery() -> WikiQuery.Open? {
        let selection = textView.selectedRange()
        guard selection.length == 0, multiCaret.isActive == false, activeLinkPopover == nil,
              let window = textView.window, window.firstResponder === textView,
              let head = textBeforeCaret(), let open = WikiQuery.open(before: head.text) else { return nil }
        let start = head.location + open.start
        guard isPlainText(NSRange(location: start, length: selection.location - start)) else { return nil }
        return WikiQuery.Open(start: start, query: open.query)
    }

    private func textBeforeCaret() -> (location: Int, text: String)? {
        let caret = textView.selectedRange().location
        guard caret > 0, caret <= storage.length else { return nil }
        let block = block(at: caret - 1)
        guard block.kind.keepsLineBreaks == false, block.kind.isAttachment == false else { return nil }
        let paragraph = paragraphRange(at: caret - 1)
        return (paragraph.location, string.substring(with: NSRange(location: paragraph.location, length: caret - paragraph.location)))
    }

    private func isPlainText(_ range: NSRange) -> Bool {
        var plain = true
        storage.enumerateAttributes(in: range) { attributes, _, stop in
            let inline = InlineStyle(rawValue: attributes[.slateInline] as? Int ?? 0)
            if attributes[.slateHref] != nil || inline.contains(.code) {
                plain = false
                stop.pointee = true
            }
        }
        return plain
    }

    private func loadWikiNames() {
        guard wikiNamesTask == nil else { return }
        let load = handlers.noteNames
        wikiNamesTask = Task { @MainActor [weak self] in
            let names = await load()
            guard let self else { return }
            wikiNamesTask = nil
            wikiNames = names
            updateWikiCompletion()
        }
    }
}
