import AppKit
import UniformTypeIdentifiers

extension RichTextController {

    func perform(_ command: EditorCommand) {
        switch command {
        case .style(let kind):
            applyParagraph(kind, toggles: false)
        case .list(let kind):
            applyParagraph(kind, toggles: true)
        case .quote:
            applyParagraph(.quote, toggles: true)
        case .inline(let style):
            toggleInline(style)
        case .link:
            editLink()
        case .image:
            chooseImage()
        case .divider:
            insertDivider()
        case .screenshot:
            handlers.requestScreenshot(.region)
        case .indent(let delta):
            _ = indentLists(by: delta)
        }
        if textView.window?.firstResponder !== textView {
            textView.window?.makeFirstResponder(textView)
        }
    }

    func applyParagraph(_ kind: BlockKind, toggles: Bool) {
        let selection = textView.selectedRange()
        if selection.length == 0, isEmptyTail(selection.location) {
            let target: BlockKind = toggles && emptyTailBlock.kind == kind ? .body : kind
            var block = emptyTailBlock.with(kind: target)
            block.group = groupFor(target, around: NSRange(location: storage.length, length: 0))
            setTailBlock(block)
            return
        }
        let paragraphs = paragraphRanges(covering: selection).filter { block(at: $0.location).kind.isAttachment == false }
        guard let first = paragraphs.first, let last = paragraphs.last else { return }
        let allSame = paragraphs.allSatisfy { block(at: $0.location).kind == kind }
        let target: BlockKind = toggles && allSame ? .body : kind
        let union = NSUnionRange(first, last)
        if target == .monospaced {
            mergeIntoCode(paragraphs, union: union)
            return
        }
        let group = groupFor(target, around: union)
        let result = NSMutableAttributedString()
        for paragraph in paragraphs {
            let source = block(at: paragraph.location)
            var target = source.with(kind: target)
            target.group = group
            if source.kind.isList, target.kind.isList { target.indent = source.indent }
            var text = storage.attributedSubstring(from: paragraph)
            if source.kind.keepsLineBreaks {
                let split = NSMutableAttributedString(attributedString: text)
                split.mutableString.replaceOccurrences(of: RichText.lineBreakString, with: "\n", options: .literal, range: NSRange(location: 0, length: split.length))
                text = split
            }
            result.append(retagged(text, as: target))
        }
        let selectionAfter = result.length == union.length ? selection : NSRange(location: union.location, length: max(result.length - 1, 0))
        replace(union, with: result, selection: selectionAfter)
    }

    private func groupFor(_ kind: BlockKind, around range: NSRange) -> Int {
        guard kind.isList || kind == .quote else { return 0 }
        return neighbourGroup(for: kind, around: range) ?? makeGroup()
    }

    private func mergeIntoCode(_ paragraphs: [NSRange], union: NSRange) {
        let lines = paragraphs.map { string.substring(with: contentRange(of: $0)).replacingOccurrences(of: "\n", with: "") }
        let block = BlockAttributes(kind: .monospaced, language: self.block(at: union.location).language)
        let result = NSMutableAttributedString(attributedString: styled(lines.joined(separator: RichText.lineBreakString), block: block))
        let endsWithNewline = NSMaxRange(union) > union.location && string.character(at: NSMaxRange(union) - 1) == 0x0A
        if endsWithNewline {
            result.append(styled("\n", block: block))
        }
        replace(union, with: result, selection: NSRange(location: union.location + result.length - (endsWithNewline ? 1 : 0), length: 0))
    }

    func toggleInline(_ style: InlineStyle) {
        let selection = textView.selectedRange()
        guard currentBlock.kind.keepsLineBreaks == false else { return }
        if selection.length == 0 {
            var current = pendingInline ?? InlineStyle(rawValue: textView.typingAttributes[.slateInline] as? Int ?? 0)
            current.formSymmetricDifference(style)
            pendingInline = current
            updateTypingAttributes()
            updateState()
            return
        }
        var all = true
        storage.enumerateAttributes(in: selection) { attributes, range, stop in
            let text = string.substring(with: range)
            guard text.allSatisfy({ $0.isWhitespace || $0 == RichText.lineBreak }) == false else { return }
            if InlineStyle(rawValue: attributes[.slateInline] as? Int ?? 0).contains(style) == false {
                all = false
                stop.pointee = true
            }
        }
        let result = NSMutableAttributedString(attributedString: storage.attributedSubstring(from: selection))
        result.enumerateAttribute(.slateInline, in: NSRange(location: 0, length: result.length)) { value, range, _ in
            var inline = InlineStyle(rawValue: value as? Int ?? 0)
            if all { inline.remove(style) } else { inline.insert(style) }
            if inline.isEmpty {
                result.removeAttribute(.slateInline, range: range)
            } else {
                result.addAttribute(.slateInline, value: inline.rawValue, range: range)
            }
        }
        replace(selection, with: result, selection: selection)
    }

    func insertDivider() {
        insertBlocks(NSAttributedString(string: RichText.attachmentString, attributes: BlockAttributes(kind: .divider).attributes))
    }

    func insertMarkdownBlocks(_ markdown: String) {
        let fragment = MarkdownReader.read(markdown)
        guard fragment.length > 0 else { return }
        insertBlocks(fragment)
    }

    func insertBlocks(_ fragment: NSAttributedString) {
        let selection = textView.selectedRange()
        let caret = selection.location
        let styledFragment = NSMutableAttributedString(attributedString: fragment)
        restyle(styledFragment, range: NSRange(location: 0, length: styledFragment.length))
        if isEmptyTail(caret) {
            let insertion = NSMutableAttributedString(attributedString: styledFragment)
            insertion.append(styled("\n", block: BlockAttributes.of(styledFragment, paragraphAt: styledFragment.length - 1)))
            replace(NSRange(location: caret, length: 0), with: insertion, selection: NSRange(location: caret + insertion.length, length: 0))
            setTailBlock(BlockAttributes())
            return
        }
        let paragraph = paragraphRange(at: caret)
        let content = contentRange(of: paragraph)
        if content.length == 0 {
            replace(content, with: styledFragment, selection: NSRange(location: NSMaxRange(content) + styledFragment.length + 1, length: 0))
            return
        }
        let current = block(at: caret)
        let insertion = NSMutableAttributedString(attributedString: styled("\n", block: current))
        insertion.append(styledFragment)
        let end = NSMaxRange(content)
        let isLast = NSMaxRange(paragraph) == storage.length && content.length == paragraph.length
        if isLast {
            insertion.append(styled("\n", block: BlockAttributes.of(styledFragment, paragraphAt: styledFragment.length - 1)))
        }
        replace(NSRange(location: end, length: 0), with: insertion, selection: NSRange(location: end + insertion.length + (isLast ? 0 : 1), length: 0))
        if isLast { setTailBlock(BlockAttributes()) }
    }

    func toggleCheckbox(at location: Int) {
        var block = block(at: location)
        guard block.kind == .checklist else { return }
        block.isDone.toggle()
        let selection = textView.selectedRange()
        let paragraph = paragraphRange(at: location)
        replace(paragraph, with: retagged(storage.attributedSubstring(from: paragraph), as: block), selection: selection)
    }

    func chooseImage() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.image]
        panel.message = "Choose images to add to the note."
        panel.prompt = "Add"
        let handlers = handlers
        panel.begin { response in
            guard response == .OK else { return }
            let urls = panel.urls
            Task { @MainActor in handlers.pasteFiles(urls) }
        }
    }
}
