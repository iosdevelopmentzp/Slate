import AppKit

extension EditorController {
    func paste(asCode: Bool) {
        let snapshot = PasteHandler.snapshot(of: .general)
        let selection = textView.selectedRange()
        let inCode = tracker.state(at: selection.location).kind.isCode
        switch PasteClassifier.classify(snapshot) {
        case .files(let urls):
            handlers.pasteFiles(urls)
        case .image(let data, let fileExtension):
            handlers.pasteImage(data, fileExtension)
        case .url(let url):
            let replacement = inCode ? url : (handlers.pasteURL(url) ?? url)
            textView.insertText(replacement, replacementRange: selection)
        case .text(let string, let language):
            if inCode {
                textView.insertText(string, replacementRange: selection)
            } else if asCode {
                insertCode(string, language: language ?? PasteClassifier.language(of: string), replacing: selection)
            } else if let language {
                textView.insertText(string, replacementRange: selection)
                suggestCode(range: NSRange(location: selection.location, length: (string as NSString).length), language: language)
            } else {
                textView.insertText(richText(snapshot) ?? string, replacementRange: selection)
            }
        case .nothing:
            break
        }
    }

    private func richText(_ snapshot: PasteboardSnapshot) -> String? {
        guard let html = snapshot.html, let converted = HTMLToMarkdown.convert(html), converted.isEmpty == false else { return nil }
        guard converted.contains("**") || converted.contains("](") || converted.contains("*") else { return nil }
        return converted
    }

    private func insertCode(_ string: String, language: String, replacing range: NSRange) {
        let fenced = PasteClassifier.fence(string, language: language)
        let text = nsText
        let atLineStart = range.location == 0 || text.character(at: range.location - 1) == 0x0A
        let atLineEnd = range.upperBound >= text.length || text.character(at: range.upperBound) == 0x0A
        let block = (atLineStart ? "" : "\n") + fenced + (atLineEnd ? "" : "\n")
        textView.apply(TextEdit(range: range, replacement: block, selection: NSRange(location: range.location + (block as NSString).length, length: 0)))
    }

    private func suggestCode(range: NSRange, language: String) {
        pendingCode = (range, language)
        container.bar.show(language: language)
        container.setBarVisible(true)
    }

    func acceptPasteSuggestion() {
        guard let pending = pendingCode else { return }
        pendingCode = nil
        container.setBarVisible(false)
        guard pending.range.upperBound <= nsText.length else { return }
        let string = nsText.substring(with: pending.range)
        insertCode(string, language: pending.language, replacing: pending.range)
    }

    func dismissPasteSuggestion() -> Bool {
        guard pendingCode != nil else { return false }
        pendingCode = nil
        container.setBarVisible(false)
        return true
    }
}
