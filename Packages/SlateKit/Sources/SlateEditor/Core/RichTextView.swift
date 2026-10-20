import AppKit

final class RichTextView: NSTextView {
    weak var controller: RichTextController?
    private var hoverArea: NSTrackingArea?

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard window?.firstResponder === self, let command = KeyboardMap.command(for: event), let controller else {
            return super.performKeyEquivalent(with: event)
        }
        controller.perform(command)
        return true
    }

    override func keyDown(with event: NSEvent) {
        if let direction = KeyboardMap.caretDirection(for: event), controller?.addCaret(direction) == true {
            return
        }
        super.keyDown(with: event)
    }

    override func insertText(_ string: Any, replacementRange: NSRange) {
        if let controller, controller.multiCaret.isActive, hasMarkedText() == false {
            let text = (string as? NSAttributedString)?.string ?? string as? String ?? ""
            if controller.typeAtCarets(text) { return }
        }
        super.insertText(string, replacementRange: replacementRange)
    }

    override func setMarkedText(_ string: Any, selectedRange: NSRange, replacementRange: NSRange) {
        controller?.dropExtraCarets()
        super.setMarkedText(string, selectedRange: selectedRange, replacementRange: replacementRange)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard hoverArea == nil else { return }
        let area = NSTrackingArea(rect: .zero, options: [.mouseMoved, .mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect], owner: self, userInfo: nil)
        addTrackingArea(area)
        hoverArea = area
    }

    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        controller?.hoverImage(at: convert(event.locationInWindow, from: nil))
        controller?.hoverHeading(at: convert(event.locationInWindow, from: nil))
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        guard event.trackingArea === hoverArea else { return }
        controller?.hoverImage(at: nil)
        controller?.hoverHeading(at: nil)
    }

    @objc func undo(_ sender: Any?) {
        controller?.undoEdit()
    }

    @objc func redo(_ sender: Any?) {
        controller?.redoEdit()
    }

    override func validateUserInterfaceItem(_ item: any NSValidatedUserInterfaceItem) -> Bool {
        switch item.action {
        case #selector(undo(_:)):
            return controller?.undoManager.canUndo == true
        case #selector(redo(_:)):
            return controller?.undoManager.canRedo == true
        case EditorMenuActions.highlight, EditorMenuActions.textColor:
            guard let state = controller?.commands?.state else { return false }
            return ColorMenu.validate(item, state: state)
        case #selector(performTextFinderAction(_:)), #selector(performFindPanelAction(_:)):
            guard let controller, let action = Self.finderAction(item) else { return false }
            return controller.finder.validateAction(action)
        default:
            return super.validateUserInterfaceItem(item)
        }
    }

    override func mouseDown(with event: NSEvent) {
        controller?.dropExtraCarets()
        if controller?.handleMouseDown(event) == true { return }
        super.mouseDown(with: event)
    }

    override func copy(_ sender: Any?) {
        guard let controller, controller.copySelection(to: PasteboardBridge.general) else {
            super.copy(sender)
            return
        }
    }

    override func cut(_ sender: Any?) {
        guard let controller, controller.copySelection(to: PasteboardBridge.general) else {
            super.cut(sender)
            return
        }
        controller.replace(selectedRange(), with: NSAttributedString(), selection: NSRange(location: selectedRange().location, length: 0))
    }

    override func paste(_ sender: Any?) {
        controller?.paste(from: PasteboardBridge.general)
    }

    override func pasteAsPlainText(_ sender: Any?) {
        guard let text = PasteboardBridge.plainText() else { return }
        controller?.insertPlain(text)
    }

    override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        let point = convert(sender.draggingLocation, from: nil)
        if controller?.drop(sender.draggingPasteboard, at: point) == true { return true }
        return super.performDragOperation(sender)
    }

    @objc func slateTitle(_ sender: Any?) { controller?.perform(.style(.title)) }
    @objc func slateHeading(_ sender: Any?) { controller?.perform(.style(.heading)) }
    @objc func slateSubheading(_ sender: Any?) { controller?.perform(.style(.subheading)) }
    @objc func slateBody(_ sender: Any?) { controller?.perform(.style(.body)) }
    @objc func slateMonospaced(_ sender: Any?) { controller?.perform(.style(.monospaced)) }
    @objc func slateChecklist(_ sender: Any?) { controller?.perform(.list(.checklist)) }
    @objc func slateBulleted(_ sender: Any?) { controller?.perform(.list(.bullet)) }
    @objc func slateNumbered(_ sender: Any?) { controller?.perform(.list(.numbered)) }
    @objc func slateQuote(_ sender: Any?) { controller?.perform(.quote) }
    @objc func slateBold(_ sender: Any?) { controller?.perform(.inline(.bold)) }
    @objc func slateItalic(_ sender: Any?) { controller?.perform(.inline(.italic)) }
    @objc func slateStrikethrough(_ sender: Any?) { controller?.perform(.inline(.strikethrough)) }
    @objc func slateCode(_ sender: Any?) { controller?.perform(.inline(.code)) }
    @objc func slateLink(_ sender: Any?) { controller?.perform(.link) }
    @objc func slateHighlight(_ sender: Any?) { controller?.perform(.highlight(ColorMenu.highlight(from: sender))) }
    @objc func slateTextColor(_ sender: Any?) { controller?.perform(.textColor(ColorMenu.textColor(from: sender))) }
    @objc func slateImage(_ sender: Any?) { controller?.perform(.image) }
    @objc func slateFile(_ sender: Any?) { controller?.perform(.file) }
    @objc func slateDivider(_ sender: Any?) { controller?.perform(.divider) }
    @objc func slateScreenshot(_ sender: Any?) { controller?.perform(.screenshot) }
    @objc func slateIndent(_ sender: Any?) { controller?.perform(.indent(1)) }
    @objc func slateOutdent(_ sender: Any?) { controller?.perform(.indent(-1)) }
    @objc func slateTable(_ sender: Any?) { controller?.perform(.table) }
    @objc func slateFormatJSON(_ sender: Any?) { controller?.perform(.formatJSON) }
    @objc func slateCaretAbove(_ sender: Any?) { _ = controller?.addCaret(.up) }
    @objc func slateCaretBelow(_ sender: Any?) { _ = controller?.addCaret(.down) }
    @objc func slatePasteTable(_ sender: Any?) { controller?.pasteAsTable(from: PasteboardBridge.general) }

    @objc func slateFind(_ sender: Any?) {
        controller?.findClient.refresh()
        controller?.finder.performAction(.showFindInterface)
    }

    override func performTextFinderAction(_ sender: Any?) {
        guard let controller, let action = Self.finderAction(sender) else { return }
        controller.findClient.refresh()
        controller.finder.performAction(action)
    }

    override func performFindPanelAction(_ sender: Any?) {
        performTextFinderAction(sender)
    }

    private static func finderAction(_ sender: Any?) -> NSTextFinder.Action? {
        guard let tag = (sender as? NSValidatedUserInterfaceItem)?.tag else { return nil }
        return NSTextFinder.Action(rawValue: tag)
    }

    @objc func slateImageSize(_ sender: NSMenuItem) {
        guard let choice = sender.representedObject as? ImageSizeChoice else { return }
        controller?.setImageWidth(at: choice.location, width: choice.width)
    }

    @objc func slateLinkAction(_ sender: NSMenuItem) {
        guard let action = LinkAction(rawValue: sender.tag), let range = (sender.representedObject as? NSValue)?.rangeValue else { return }
        controller?.performLinkAction(action, range: range)
    }

    @objc func slateOutline(_ sender: Any?) { controller?.perform(.outline) }
    @objc func slateCollapseSection(_ sender: Any?) { controller?.perform(.collapseSection) }
    @objc func slateExpandSection(_ sender: Any?) { controller?.perform(.expandSection) }
    @objc func slateCollapseAllSections(_ sender: Any?) { controller?.perform(.collapseAllSections) }
    @objc func slateExpandAllSections(_ sender: Any?) { controller?.perform(.expandAllSections) }

    @objc func slateJumpToHeading(_ sender: NSMenuItem) {
        controller?.jumpToHeading(at: sender.tag)
    }

    @objc func slateCodeLanguage(_ sender: NSMenuItem) {
        guard let choice = sender.representedObject as? CodeLanguageChoice else { return }
        controller?.setCodeLanguage(at: choice.location, fence: choice.fence)
    }

    @objc func slateImageAction(_ sender: NSMenuItem) {
        guard let choice = sender.representedObject as? ImageMenuChoice else { return }
        controller?.handlers.attachment(choice.path, choice.action)
    }
}
