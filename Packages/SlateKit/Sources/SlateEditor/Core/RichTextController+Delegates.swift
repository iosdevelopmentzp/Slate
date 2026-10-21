import AppKit

extension RichTextController: NSTextViewDelegate, NSTextStorageDelegate, NSTextLayoutManagerDelegate, NSTextContentStorageDelegate {

    func textDidChange(_ notification: Notification) {
        textChanged()
    }

    func textViewDidChangeSelection(_ notification: Notification) {
        guard isEditingInternally == false else { return }
        if multiCaret.isApplying == false { dropExtraCarets() }
        pendingInline = nil
        updateTypingAttributes()
        updateState()
        updateLinkBar()
    }

    func textDidEndEditing(_ notification: Notification) {
        linkBar.hide()
        flush()
        handlers.didEndEditing()
    }

    func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        handle(commandSelector)
    }

    func textView(_ textView: NSTextView, willChangeSelectionFromCharacterRange oldSelectedCharRange: NSRange, toCharacterRange newSelectedCharRange: NSRange) -> NSRange {
        visibleSelection(from: oldSelectedCharRange, to: newSelectedCharRange)
    }

    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
        unfoldSections(touching: affectedCharRange, replacement: replacementString)
        return shouldChange(affectedCharRange, replacement: replacementString)
    }

    func undoManager(for view: NSTextView) -> UndoManager? {
        undoManager
    }

    func textView(_ view: NSTextView, menu: NSMenu, for event: NSEvent, at charIndex: Int) -> NSMenu? {
        if let image = imageMenu(at: charIndex) { return image }
        if commands?.state.canFormatInline == true { ColorMenu.prepend(to: menu) }
        return linkMenu(at: charIndex, adding: menu) ?? menu
    }

    func textStorage(_ textStorage: NSTextStorage, willProcessEditing editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int) {
        guard editedMask.contains(.editedCharacters) else { return }
        finder.noteClientStringWillChange()
    }

    func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int) {
        imageButton.hide()
        imageHandle.hide()
        if editedMask.contains(.editedCharacters) {
            findClient.storageChanged()
            clearMatchHighlights()
            shiftFolds(editedRange: editedRange, delta: delta)
        }
        storageEdited(editedMask, range: editedRange, delta: delta)
    }

    func textLayoutManager(_ textLayoutManager: NSTextLayoutManager, textLayoutFragmentFor location: any NSTextLocation, in textElement: NSTextElement) -> NSTextLayoutFragment {
        guard let paragraph = textElement as? NSTextParagraph, paragraph.attributedString.length > 0 else {
            return NSTextLayoutFragment(textElement: textElement, range: textElement.elementRange)
        }
        let attributes = paragraph.attributedString.attributes(at: 0, effectiveRange: nil)
        let decoration = ParagraphDecoration.of(attributes)
        let isHeading = BlockAttributes(attributes).kind.headingLevel != nil
        guard decoration != .none || isHeading else {
            return NSTextLayoutFragment(textElement: textElement, range: textElement.elementRange)
        }
        let fragment = RichLayoutFragment(textElement: textElement, range: textElement.elementRange)
        fragment.decoration = decoration
        if isHeading {
            fragment.fold = foldMark(at: textLayoutManager.offset(from: textLayoutManager.documentRange.location, to: location))
        }
        fragment.colors = styler.configuration.colors
        fragment.fontSize = (attributes[.font] as? NSFont)?.pointSize ?? styler.size(for: .body)
        if decoration == .block(raw: false) {
            fragment.languageLabel = CodeLanguage.label(for: attributes[.slateLanguage] as? String)
        }
        return fragment
    }

    func textContentManager(_ textContentManager: NSTextContentManager, shouldEnumerate textElement: NSTextElement, options: NSTextContentManager.EnumerationOptions) -> Bool {
        guard hiddenSections.isEmpty == false, let start = textElement.elementRange?.location else { return true }
        return isHidden(textContentManager.offset(from: textContentManager.documentRange.location, to: start)) == false
    }
}
