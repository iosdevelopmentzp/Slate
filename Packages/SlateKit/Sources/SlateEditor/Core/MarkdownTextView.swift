import AppKit

final class MarkdownTextView: NSTextView {
    weak var controller: EditorController?
    private var hoverArea: NSTrackingArea?

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if controller?.handleMouseDown(at: point, event: event) == true { return }
        super.mouseDown(with: event)
    }

    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        controller?.mouseMoved(to: convert(event.locationInWindow, from: nil))
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        controller?.mouseExited()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let hoverArea { removeTrackingArea(hoverArea) }
        let area = NSTrackingArea(rect: .zero, options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self)
        addTrackingArea(area)
        hoverArea = area
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        let point = convert(event.locationInWindow, from: nil)
        return controller?.contextMenu(at: point) ?? super.menu(for: event)
    }

    override func insertNewline(_ sender: Any?) {
        if controller?.handleNewline() == true { return }
        super.insertNewline(sender)
    }

    override func insertTab(_ sender: Any?) {
        if controller?.handleTab(outdent: false) == true { return }
        super.insertTab(sender)
    }

    override func insertBacktab(_ sender: Any?) {
        if controller?.handleTab(outdent: true) == true { return }
        super.insertBacktab(sender)
    }

    override func cancelOperation(_ sender: Any?) {
        if controller?.dismissPasteSuggestion() == true { return }
        guard let next = nextResponder, next.tryToPerform(#selector(NSResponder.cancelOperation(_:)), with: sender) else {
            super.cancelOperation(sender)
            return
        }
    }

    @objc func slateBold(_ sender: Any?) { controller?.wrap(with: "**") }
    @objc func slateItalic(_ sender: Any?) { controller?.wrap(with: "*") }
    @objc func slateCode(_ sender: Any?) { controller?.wrap(with: "`") }
    @objc func slateLink(_ sender: Any?) { controller?.insertLink() }
    @objc func slateToggleCheckbox(_ sender: Any?) { controller?.toggleCurrentLine() }
    @objc func slateMoveLineUp(_ sender: Any?) { controller?.moveLine(up: true) }
    @objc func slateMoveLineDown(_ sender: Any?) { controller?.moveLine(up: false) }
    @objc func slateDuplicateLine(_ sender: Any?) { controller?.duplicateLine() }
    @objc func slateToggleComment(_ sender: Any?) { controller?.toggleComment() }
    @objc func slatePasteAsCode(_ sender: Any?) { controller?.paste(asCode: true) }
    @objc func slateFind(_ sender: Any?) { controller?.showFind(replace: false) }
    @objc func slateFindAndReplace(_ sender: Any?) { controller?.showFind(replace: true) }
    @objc func slateScreenshot(_ sender: Any?) { controller?.handlers.requestScreenshot(.region) }
    @objc func slateWindowScreenshot(_ sender: Any?) { controller?.handlers.requestScreenshot(.window) }
    @objc func slateOpenLink(_ sender: Any?) { controller?.openLinkAtCaret() }

    override func insertText(_ string: Any, replacementRange: NSRange) {
        if (string as? String) == "`", replacementRange.location == NSNotFound, controller?.handleBacktick() == true { return }
        super.insertText(string, replacementRange: replacementRange)
    }

    override func paste(_ sender: Any?) {
        controller?.paste(asCode: false)
    }

    override func pasteAsPlainText(_ sender: Any?) {
        controller?.paste(asCode: false)
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard window?.firstResponder === self, let controller else { return super.performKeyEquivalent(with: event) }
        if controller.handleKeyEquivalent(event) { return true }
        return super.performKeyEquivalent(with: event)
    }

    override var rangeForUserCompletion: NSRange {
        controller?.completionContext()?.range ?? super.rangeForUserCompletion
    }

    override func insertCompletion(_ word: String, forPartialWordRange charRange: NSRange, movement: Int, isFinal flag: Bool) {
        let completed = controller?.completionText(word, range: charRange, movement: movement, isFinal: flag) ?? word
        super.insertCompletion(completed, forPartialWordRange: charRange, movement: movement, isFinal: flag)
    }

    func apply(_ edit: TextEdit) {
        guard shouldChangeText(in: edit.range, replacementString: edit.replacement) else { return }
        textStorage?.replaceCharacters(in: edit.range, with: edit.replacement)
        didChangeText()
        setSelectedRange(edit.selection)
        scrollRangeToVisible(edit.selection)
    }

    func replace(_ range: NSRange, with string: String) {
        guard shouldChangeText(in: range, replacementString: string) else { return }
        textStorage?.replaceCharacters(in: range, with: string)
        didChangeText()
    }
}
