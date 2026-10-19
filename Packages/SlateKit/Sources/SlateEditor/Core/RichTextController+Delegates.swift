import AppKit

extension RichTextController: NSTextViewDelegate, NSTextStorageDelegate, NSTextLayoutManagerDelegate {

    func textDidChange(_ notification: Notification) {
        textChanged()
    }

    func textViewDidChangeSelection(_ notification: Notification) {
        guard isEditingInternally == false else { return }
        if multiCaret.isApplying == false { dropExtraCarets() }
        pendingInline = nil
        updateTypingAttributes()
        updateState()
    }

    func textDidEndEditing(_ notification: Notification) {
        flush()
        handlers.didEndEditing()
    }

    func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        handle(commandSelector)
    }

    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
        shouldChange(affectedCharRange, replacement: replacementString)
    }

    func undoManager(for view: NSTextView) -> UndoManager? {
        undoManager
    }

    func textView(_ view: NSTextView, menu: NSMenu, for event: NSEvent, at charIndex: Int) -> NSMenu? {
        imageMenu(at: charIndex) ?? menu
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
        }
        storageEdited(editedMask, range: editedRange, delta: delta)
    }

    func textLayoutManager(_ textLayoutManager: NSTextLayoutManager, textLayoutFragmentFor location: any NSTextLocation, in textElement: NSTextElement) -> NSTextLayoutFragment {
        guard let paragraph = textElement as? NSTextParagraph, paragraph.attributedString.length > 0 else {
            return NSTextLayoutFragment(textElement: textElement, range: textElement.elementRange)
        }
        let attributes = paragraph.attributedString.attributes(at: 0, effectiveRange: nil)
        let decoration = ParagraphDecoration.of(attributes)
        guard decoration != .none else {
            return NSTextLayoutFragment(textElement: textElement, range: textElement.elementRange)
        }
        let fragment = RichLayoutFragment(textElement: textElement, range: textElement.elementRange)
        fragment.decoration = decoration
        fragment.colors = styler.configuration.colors
        fragment.fontSize = (attributes[.font] as? NSFont)?.pointSize ?? styler.size(for: .body)
        return fragment
    }
}
