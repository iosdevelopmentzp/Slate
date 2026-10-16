import AppKit

extension EditorController {
    func handleNewline() -> Bool {
        if pendingCode != nil {
            acceptPasteSuggestion()
            return true
        }
        let selection = textView.selectedRange()
        let line = tracker.state(at: selection.location)
        if case .fenceOpen = line.kind, selection.length == 0, selection.location == line.range.upperBound, line.openFence != nil,
           isUnclosedFence(from: line), let closing = FenceCompletion.closingFence(afterLine: nsText.substring(with: line.range), isUnclosed: true) {
            let insertion = "\n\n" + closing
            textView.apply(TextEdit(range: selection, replacement: insertion, selection: NSRange(location: selection.location + 1, length: 0)))
            return true
        }
        guard line.kind.isCode == false,
              let edit = ListEditing.newline(in: nsText, selection: selection) else { return false }
        textView.apply(edit)
        return true
    }

    private func isUnclosedFence(from line: LineState) -> Bool {
        let index = tracker.lineIndex(containing: line.start)
        return tracker.lines[(index + 1)...].contains { $0.kind == .fenceClose } == false
    }

    func moveLine(up: Bool) {
        guard let edit = LineCommands.moveLines(in: nsText, selection: textView.selectedRange(), up: up) else { return }
        textView.apply(edit)
    }

    func duplicateLine() {
        textView.apply(LineCommands.duplicateLines(in: nsText, selection: textView.selectedRange()))
    }

    func toggleComment() {
        let selection = textView.selectedRange()
        guard case .code(let language) = tracker.state(at: selection.location).kind else { return }
        textView.apply(LineCommands.toggleComment(in: nsText, selection: selection, prefix: LineCommands.commentPrefix(for: language)))
    }

    func handleBacktick() -> Bool {
        let selection = textView.selectedRange()
        guard tracker.state(at: selection.location).kind.isCode == false, let edit = FenceCompletion.backtick(in: nsText, selection: selection) else { return false }
        if edit.replacement.isEmpty, edit.range.length == 0 {
            textView.setSelectedRange(edit.selection)
            return true
        }
        textView.apply(edit)
        return true
    }

    func showFind(replace: Bool) {
        let item = NSMenuItem()
        item.tag = replace ? NSTextFinder.Action.showReplaceInterface.rawValue : NSTextFinder.Action.showFindInterface.rawValue
        textView.performTextFinderAction(item)
    }

    func reveal(location: Int) {
        let range = NSRange(location: min(location, nsText.length), length: 0)
        textView.window?.makeFirstResponder(textView)
        textView.setSelectedRange(range)
        textView.scrollRangeToVisible(range)
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
        case ([.option], _) where event.keyCode == 126:
            moveLine(up: true)
        case ([.option], _) where event.keyCode == 125:
            moveLine(up: false)
        case ([.command], "d"):
            duplicateLine()
        case ([.command], "/"):
            toggleComment()
        case ([.command], "f"):
            showFind(replace: false)
        case ([.command, .option], "f"):
            showFind(replace: true)
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
