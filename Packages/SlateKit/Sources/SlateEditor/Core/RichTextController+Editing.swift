import AppKit

extension RichTextController {
    static let shortcuts: [String: BlockKind] = ["-": .bullet, "*": .bullet, "1.": .numbered, "[]": .checklist, "[ ]": .checklist, "#": .title, "##": .heading, "###": .subheading, ">": .quote]

    func handle(_ selector: Selector) -> Bool {
        let flags = NSApp.currentEvent?.modifierFlags.intersection(.deviceIndependentFlagsMask) ?? []
        switch selector {
        case #selector(NSResponder.insertNewline(_:)):
            return flags.contains(.shift) ? insertSoftBreak() : handleReturn()
        case #selector(NSResponder.insertLineBreak(_:)), #selector(NSResponder.insertNewlineIgnoringFieldEditor(_:)):
            return insertSoftBreak()
        case #selector(NSResponder.insertTab(_:)):
            return indentLists(by: 1)
        case #selector(NSResponder.insertBacktab(_:)):
            return indentLists(by: -1)
        case #selector(NSResponder.deleteBackward(_:)):
            return handleBackspace()
        default:
            return false
        }
    }

    func replace(_ range: NSRange, with text: NSAttributedString, selection: NSRange?) {
        isEditingInternally = true
        guard textView.shouldChangeText(in: range, replacementString: text.string) else {
            isEditingInternally = false
            return
        }
        storage.replaceCharacters(in: range, with: text)
        isEditingInternally = false
        textView.didChangeText()
        if let selection {
            textView.setSelectedRange(NSRange(location: min(selection.location, storage.length), length: min(selection.length, max(storage.length - selection.location, 0))))
        }
    }

    func styled(_ string: String, block: BlockAttributes, inline: InlineStyle = []) -> NSAttributedString {
        NSAttributedString(string: string, attributes: styler.attributes(block: block, inline: inline, href: nil))
    }

    func retagged(_ text: NSAttributedString, as block: BlockAttributes) -> NSAttributedString {
        let copy = NSMutableAttributedString(attributedString: text)
        let range = NSRange(location: 0, length: copy.length)
        for key in NSAttributedString.Key.blockKeys {
            copy.removeAttribute(key, range: range)
        }
        copy.addAttributes(block.attributes, range: range)
        return copy
    }

    func setTailBlock(_ block: BlockAttributes) {
        emptyTailBlock = block
        updateTypingAttributes()
        updateState()
    }

    func setBlock(_ block: BlockAttributes, ofParagraphAt location: Int) {
        if isEmptyTail(location) {
            setTailBlock(block)
            return
        }
        let paragraph = paragraphRange(at: location)
        let selection = textView.selectedRange()
        replace(paragraph, with: retagged(storage.attributedSubstring(from: paragraph), as: block), selection: selection)
    }

    private func nextBlock(after block: BlockAttributes) -> BlockAttributes {
        switch block.kind {
        case .title, .heading, .subheading, .image, .divider: BlockAttributes()
        case .checklist: BlockAttributes(kind: .checklist, indent: block.indent, group: block.group)
        default: block
        }
    }

    private func endedBlock(_ block: BlockAttributes) -> BlockAttributes {
        if block.kind.isList, block.indent > 0 {
            var outdented = block
            outdented.indent -= 1
            return outdented
        }
        return BlockAttributes()
    }

    func handleReturn() -> Bool {
        let selection = textView.selectedRange()
        guard selection.length == 0 else { return false }
        let caret = selection.location
        let block = block(at: caret)
        if isEmptyTail(caret) {
            if block.kind.isList || block.kind == .quote {
                setTailBlock(endedBlock(block))
                return true
            }
            replace(NSRange(location: caret, length: 0), with: styled("\n", block: block), selection: NSRange(location: caret + 1, length: 0))
            setTailBlock(nextBlock(after: block))
            return true
        }
        let paragraph = paragraphRange(at: caret)
        let content = contentRange(of: paragraph)
        switch block.kind {
        case .monospaced, .raw:
            return returnInBlock(block, caret: caret, paragraph: paragraph, content: content)
        case .bullet, .numbered, .checklist, .quote:
            if content.length == 0 {
                setBlock(endedBlock(block), ofParagraphAt: caret)
                return true
            }
            splitParagraph(at: caret, paragraph: paragraph, next: nextBlock(after: block))
            return true
        case .title, .heading, .subheading:
            if caret == content.location, content.length > 0 {
                replace(NSRange(location: caret, length: 0), with: styled("\n", block: BlockAttributes()), selection: NSRange(location: caret + 1, length: 0))
                return true
            }
            splitParagraph(at: caret, paragraph: paragraph, next: BlockAttributes())
            return true
        case .image, .divider:
            if caret == content.location {
                replace(NSRange(location: caret, length: 0), with: styled("\n", block: BlockAttributes()), selection: NSRange(location: caret + 1, length: 0))
            } else {
                splitParagraph(at: NSMaxRange(content), paragraph: paragraph, next: BlockAttributes())
            }
            return true
        case .body:
            return false
        }
    }

    func splitParagraph(at caret: Int, paragraph: NSRange, next: BlockAttributes) {
        let current = BlockAttributes(storage.attributes(at: paragraph.location, effectiveRange: nil))
        let rest = NSRange(location: caret, length: NSMaxRange(paragraph) - caret)
        let replacement = NSMutableAttributedString(attributedString: styled("\n", block: current))
        let hasTerminator = NSMaxRange(paragraph) > paragraph.location && string.character(at: NSMaxRange(paragraph) - 1) == 0x0A
        if rest.length > 0 {
            replacement.append(retagged(storage.attributedSubstring(from: rest), as: next))
        }
        replace(rest, with: replacement, selection: NSRange(location: caret + 1, length: 0))
        if hasTerminator == false, rest.length == 0 {
            setTailBlock(next)
        }
    }

    private func returnInBlock(_ block: BlockAttributes, caret: Int, paragraph: NSRange, content: NSRange) -> Bool {
        let before = string.substring(with: NSRange(location: content.location, length: caret - content.location))
        let lineIsEmpty = before.isEmpty || before.hasSuffix(RichText.lineBreakString)
        if caret == NSMaxRange(content), lineIsEmpty, content.length > 0 {
            let removal = before.hasSuffix(RichText.lineBreakString) ? 1 : 0
            let start = caret - removal
            let tail = NSRange(location: start, length: NSMaxRange(paragraph) - start)
            let replacement = NSMutableAttributedString(attributedString: styled("\n", block: block))
            if tail.length > removal {
                replacement.append(styled("\n", block: BlockAttributes()))
            }
            replace(tail, with: replacement, selection: NSRange(location: start + 1, length: 0))
            if tail.length == removal { setTailBlock(BlockAttributes()) }
            return true
        }
        replace(NSRange(location: caret, length: 0), with: styled(RichText.lineBreakString, block: block), selection: NSRange(location: caret + 1, length: 0))
        return true
    }

    func insertSoftBreak() -> Bool {
        let selection = textView.selectedRange()
        let block = block(at: selection.location)
        guard block.kind.isHeading == false, block.kind.isAttachment == false else { return true }
        replace(selection, with: styled(RichText.lineBreakString, block: block), selection: NSRange(location: selection.location + 1, length: 0))
        return true
    }

    func handleBackspace() -> Bool {
        let selection = textView.selectedRange()
        guard selection.length == 0 else { return false }
        let caret = selection.location
        if isEmptyTail(caret) {
            guard emptyTailBlock.kind != .body else { return false }
            setTailBlock(endedBlock(emptyTailBlock))
            return true
        }
        let paragraph = paragraphRange(at: caret)
        guard caret == paragraph.location else { return false }
        let block = block(at: caret)
        switch block.kind {
        case .bullet, .numbered, .checklist:
            setBlock(endedBlock(block), ofParagraphAt: caret)
            return true
        case .quote, .title, .heading, .subheading, .monospaced, .raw:
            setBlock(BlockAttributes(), ofParagraphAt: caret)
            return true
        case .image, .divider:
            return false
        case .body:
            guard caret > 0 else { return false }
            let previous = paragraphRange(at: caret - 1)
            guard self.block(at: previous.location).kind.isAttachment else { return false }
            replace(previous, with: NSAttributedString(), selection: NSRange(location: previous.location, length: 0))
            return true
        }
    }

    func indentLists(by delta: Int) -> Bool {
        let selection = textView.selectedRange()
        if isEmptyTail(selection.location), selection.length == 0 {
            guard emptyTailBlock.kind.isList else { return false }
            var block = emptyTailBlock
            block.indent = clampedIndent(block.indent + delta, before: storage.length)
            setTailBlock(block)
            return true
        }
        let paragraphs = paragraphRanges(covering: selection)
        guard paragraphs.contains(where: { block(at: $0.location).kind.isList }) else { return false }
        let union = NSUnionRange(paragraphs[0], paragraphs[paragraphs.count - 1])
        let result = NSMutableAttributedString()
        for paragraph in paragraphs {
            let text = storage.attributedSubstring(from: paragraph)
            var block = block(at: paragraph.location)
            if block.kind.isList {
                block.indent = clampedIndent(block.indent + delta, before: paragraph.location, previousInSelection: result)
                result.append(retagged(text, as: block))
            } else {
                result.append(text)
            }
        }
        replace(union, with: result, selection: selection)
        return true
    }

    private func clampedIndent(_ wanted: Int, before location: Int, previousInSelection: NSAttributedString? = nil) -> Int {
        var limit = 0
        if let previousInSelection, previousInSelection.length > 0 {
            let previous = BlockAttributes.of(previousInSelection, paragraphAt: previousInSelection.length - 1)
            limit = previous.kind.isList ? previous.indent + 1 : 0
        } else if location > 0 {
            let previous = block(at: paragraphRange(at: location - 1).location)
            limit = previous.kind.isList ? previous.indent + 1 : 0
        }
        return min(max(wanted, 0), min(limit, RichText.maxIndent))
    }

    func paragraphRanges(covering selection: NSRange) -> [NSRange] {
        guard storage.length > 0 else { return [] }
        let start = min(selection.location, storage.length - 1)
        let end = max(start, min(NSMaxRange(selection) - (selection.length > 0 ? 1 : 0), storage.length - 1))
        var ranges: [NSRange] = []
        var location = paragraphRange(at: start).location
        while location <= end, location < storage.length {
            let paragraph = paragraphRange(at: location)
            ranges.append(paragraph)
            location = NSMaxRange(paragraph)
        }
        return ranges
    }

    func shouldChange(_ range: NSRange, replacement: String?) -> Bool {
        guard isEditingInternally == false, let replacement, replacement.isEmpty == false, storage.length > 0, isEmptyTail(range.location) == false else { return true }
        let paragraph = paragraphRange(at: range.location)
        let content = contentRange(of: paragraph)
        let block = block(at: range.location)
        if block.kind.isAttachment, range.length == 0, replacement != "\n" {
            if range.location == content.location {
                let inserted = NSMutableAttributedString(attributedString: styled(replacement, block: BlockAttributes()))
                inserted.append(styled("\n", block: BlockAttributes()))
                replace(range, with: inserted, selection: NSRange(location: range.location + (replacement as NSString).length, length: 0))
                return false
            }
            if range.location == NSMaxRange(content) {
                let inserted = NSMutableAttributedString(attributedString: styled("\n", block: block))
                inserted.append(styled(replacement, block: BlockAttributes()))
                replace(range, with: inserted, selection: NSRange(location: range.location + 1 + (replacement as NSString).length, length: 0))
                return false
            }
        }
        if replacement == " ", range.length == 0, block.kind == .body, range.location > content.location {
            let prefix = string.substring(with: NSRange(location: content.location, length: range.location - content.location))
            if let kind = Self.shortcuts[prefix] {
                var target = BlockAttributes(kind: kind)
                if kind.isList || kind == .quote { target.group = neighbourGroup(for: kind, around: paragraph) ?? makeGroup() }
                let rest = NSRange(location: range.location, length: NSMaxRange(paragraph) - range.location)
                let text = retagged(storage.attributedSubstring(from: rest), as: target)
                replace(NSRange(location: content.location, length: NSMaxRange(paragraph) - content.location), with: text, selection: NSRange(location: content.location, length: 0))
                if rest.length == 0 { setTailBlock(target) }
                return false
            }
        }
        return true
    }

    func neighbourGroup(for kind: BlockKind, around paragraph: NSRange) -> Int? {
        let matches: (BlockAttributes) -> Bool = { other in kind.isList ? other.kind.isList : other.kind == kind }
        if paragraph.location > 0 {
            let previous = block(at: paragraphRange(at: paragraph.location - 1).location)
            if matches(previous), previous.group != 0 { return previous.group }
        }
        if NSMaxRange(paragraph) < storage.length {
            let next = block(at: NSMaxRange(paragraph))
            if matches(next), next.group != 0 { return next.group }
        }
        return nil
    }
}
