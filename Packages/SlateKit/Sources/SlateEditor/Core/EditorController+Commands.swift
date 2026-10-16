import AppKit

extension EditorController {
    func handleNewline() -> Bool {
        if pendingCode != nil {
            acceptPasteSuggestion()
            return true
        }
        let selection = textView.selectedRange()
        guard tracker.state(at: selection.location).kind.isCode == false,
              let edit = ListEditing.newline(in: nsText, selection: selection) else { return false }
        textView.apply(edit)
        return true
    }

    func handleTab(outdent: Bool) -> Bool {
        let selection = textView.selectedRange()
        if tracker.state(at: selection.location).kind.isCode {
            guard outdent == false else { return true }
            textView.insertText("    ", replacementRange: selection)
            return true
        }
        guard let edit = ListEditing.indent(in: nsText, selection: selection, outdent: outdent) else { return false }
        textView.apply(edit)
        return true
    }

    func handleKeyEquivalent(_ event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask).subtracting([.capsLock, .numericPad, .function])
        let key = event.charactersIgnoringModifiers?.lowercased() ?? ""
        switch (flags, key) {
        case ([.command], "b"):
            wrap(with: "**")
        case ([.command], "i"):
            wrap(with: "*")
        case ([.command], "`"):
            wrap(with: "`")
        case ([.command, .shift], "l"):
            toggleCurrentLine()
        case ([.command, .shift], "v"):
            paste(asCode: true)
        case ([.command, .shift], "s"):
            handlers.requestScreenshot(.region)
        case ([.command, .shift], "w"):
            handlers.requestScreenshot(.window)
        case ([.command, .shift], "k"):
            insertLink()
        case ([.command], "\r"):
            openLinkAtCaret()
        default:
            return false
        }
        return true
    }

    func wrap(with marker: String) {
        textView.apply(WrapSelection.wrap(nsText, selection: textView.selectedRange(), marker: marker))
    }

    func toggleCurrentLine() {
        let selection = textView.selectedRange()
        let lineRange = ListEditing.contentRange(of: nsText.lineRange(for: NSRange(location: selection.location, length: 0)), in: nsText)
        let line = nsText.substring(with: lineRange)
        let cycled = CheckboxToggle.cycled(line)
        let caret = min(selection.location + ((cycled as NSString).length - lineRange.length), lineRange.location + (cycled as NSString).length)
        textView.apply(TextEdit(range: lineRange, replacement: cycled, selection: NSRange(location: max(lineRange.location, caret), length: 0)))
    }

    func toggleCheckbox(lineAt location: Int) {
        let line = tracker.state(at: location)
        guard case .listItem(let item) = line.kind, let box = item.checkbox else { return }
        textView.replace(NSRange(location: line.start + box.range.location + 1, length: 1), with: box.isChecked ? " " : "x")
    }

    func insertLink() {
        let selection = textView.selectedRange()
        let selected = nsText.substring(with: selection)
        let url = PasteHandler.clipboardURL ?? ""
        let label = selected.isEmpty ? "text" : selected
        let markdown = "[\(label)](\(url))"
        let labelRange = NSRange(location: selection.location + 1, length: (label as NSString).length)
        let urlRange = NSRange(location: selection.location + 3 + (label as NSString).length, length: (url as NSString).length)
        textView.apply(TextEdit(range: selection, replacement: markdown, selection: selected.isEmpty || url.isEmpty ? (selected.isEmpty ? labelRange : urlRange) : NSRange(location: selection.location + (markdown as NSString).length, length: 0)))
    }

    func insertBlock(_ markdown: String) {
        let selection = textView.selectedRange()
        let text = nsText
        let atLineStart = selection.location == 0 || text.character(at: selection.location - 1) == 0x0A
        let atLineEnd = selection.upperBound >= text.length || text.character(at: selection.upperBound) == 0x0A
        let block = (atLineStart ? "" : "\n") + markdown + (atLineEnd ? "" : "\n")
        let caret = selection.location + (block as NSString).length
        textView.apply(TextEdit(range: selection, replacement: block, selection: NSRange(location: caret, length: 0)))
    }

    func link(at location: Int) -> EditorLink? {
        let line = tracker.state(at: location)
        guard line.kind.isCode == false else { return nil }
        let string = nsText.substring(with: line.range)
        let offset = location - line.start
        let spans = InlineScanner(patterns: CompiledLinkPattern.compile(styler.configuration.linkPatterns)).spans(in: string)
        for span in spans where span.range.location <= offset && offset <= span.range.upperBound {
            switch span.kind {
            case .link(let target), .url(let target): return .url(target)
            case .wikilink(let target): return .wiki(target)
            case .pattern(let id, let match): return .pattern(id: id, match: match)
            default: continue
            }
        }
        if case .image(let source, _) = line.kind {
            return .url(source)
        }
        return nil
    }

    func openLinkAtCaret() {
        guard let link = link(at: textView.selectedRange().location) else { return }
        handlers.openLink(link)
    }

    @objc func copyCodeBlock() {
        guard let range = copyButton.blockRange else { return }
        PasteHandler.copy(nsText.substring(with: range))
        copyButton.title = "Copied"
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(1.2))
            guard let self else { return }
            copyButton.title = "Copy"
        }
    }

    func codeBlock(containingLine index: Int) -> (open: Int, content: NSRange)? {
        let lines = tracker.lines
        guard lines.indices.contains(index), lines[index].kind.isCode else { return nil }
        var open = index
        while open > 0 {
            if case .fenceOpen = lines[open].kind { break }
            open -= 1
        }
        guard case .fenceOpen = lines[open].kind else { return nil }
        var close = open + 1
        while close < lines.count, lines[close].kind != .fenceClose {
            close += 1
        }
        let first = open + 1
        guard first < lines.count, first < close || close == lines.count else {
            return (open, NSRange(location: lines[open].range.upperBound, length: 0))
        }
        let last = min(close, lines.count) - 1
        guard last >= first else { return (open, NSRange(location: lines[open].range.upperBound, length: 0)) }
        let start = lines[first].start
        let end = lines[last].range.upperBound
        return (open, NSRange(location: start, length: end - start))
    }
}
