import AppKit

final class TableCellEditor: NSTextView {
    weak var table: TableBlockView?
    let cellUndo = UndoManager()
    var style = TableStyle()
    var isHeader = false
    var cellAlignment = TableAlignment.none
    private var linkPopover: LinkPopover?

    static func make() -> TableCellEditor {
        let editor = TableCellEditor(usingTextLayoutManager: true)
        editor.isRichText = true
        editor.importsGraphics = false
        editor.allowsUndo = true
        editor.usesFontPanel = false
        editor.drawsBackground = false
        editor.isAutomaticQuoteSubstitutionEnabled = false
        editor.isAutomaticDashSubstitutionEnabled = false
        editor.isAutomaticTextReplacementEnabled = false
        editor.isAutomaticLinkDetectionEnabled = false
        editor.isAutomaticDataDetectionEnabled = false
        editor.textContainerInset = .zero
        editor.textContainer?.lineFragmentPadding = 0
        editor.textContainer?.widthTracksTextView = true
        editor.isVerticallyResizable = false
        editor.isHorizontallyResizable = false
        editor.focusRingType = .none
        editor.setAccessibilityLabel("Table cell")
        return editor
    }

    func load(_ text: NSAttributedString, style: TableStyle, header: Bool, alignment: TableAlignment) {
        self.style = style
        isHeader = header
        cellAlignment = alignment
        textStorage?.setAttributedString(text)
        typingAttributes = style.typingAttributes(header: header, alignment: alignment)
        cellUndo.removeAllActions()
    }

    var markdown: String {
        TableCellText.markdown(of: textStorage ?? NSAttributedString())
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard window?.firstResponder === self, let command = KeyboardMap.command(for: event) else {
            return super.performKeyEquivalent(with: event)
        }
        switch command {
        case .inline(let style):
            toggle(style)
            return true
        case .link:
            editLink()
            return true
        default:
            return super.performKeyEquivalent(with: event)
        }
    }

    @objc func slateBold(_ sender: Any?) { toggle(.bold) }
    @objc func slateItalic(_ sender: Any?) { toggle(.italic) }
    @objc func slateStrikethrough(_ sender: Any?) { toggle(.strikethrough) }
    @objc func slateCode(_ sender: Any?) { toggle(.code) }
    @objc func slateLink(_ sender: Any?) { editLink() }

    override func paste(_ sender: Any?) {
        guard let table, let host = table.host else {
            super.paste(sender)
            return
        }
        host.pasteIntoCell(table)
    }

    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2, let path = imagePath(at: convert(event.locationInWindow, from: nil)) {
            table?.host?.imageAction(path, .quickLook)
            return
        }
        super.mouseDown(with: event)
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        let menu = super.menu(for: event) ?? NSMenu()
        guard let table, let path = imagePath(at: convert(event.locationInWindow, from: nil)) else { return menu }
        return ImageMenu.prepend(path: path, target: table, action: #selector(TableBlockView.cellImageAction(_:)), to: menu)
    }

    override func selectAll(_ sender: Any?) {
        let length = (string as NSString).length
        guard let table, selectedRange() == NSRange(location: 0, length: length) else {
            super.selectAll(sender)
            return
        }
        table.selectWholeTable()
    }

    func imagePath(at point: CGPoint) -> String? {
        guard let storage = textStorage, storage.length > 0 else { return nil }
        let index = characterIndexForInsertion(at: point)
        for candidate in [index, index - 1] where candidate >= 0 && candidate < storage.length {
            if let path = storage.attribute(.slateImagePath, at: candidate, effectiveRange: nil) as? String {
                return path
            }
        }
        return nil
    }

    @objc func undo(_ sender: Any?) {
        if cellUndo.canUndo {
            cellUndo.undo()
            didChangeText()
        } else {
            table?.undoOutside()
        }
    }

    @objc func redo(_ sender: Any?) {
        if cellUndo.canRedo {
            cellUndo.redo()
            didChangeText()
        } else {
            table?.redoOutside()
        }
    }

    override func validateUserInterfaceItem(_ item: any NSValidatedUserInterfaceItem) -> Bool {
        switch item.action {
        case #selector(undo(_:)), #selector(redo(_:)), #selector(slateBold(_:)), #selector(slateItalic(_:)), #selector(slateStrikethrough(_:)), #selector(slateCode(_:)), #selector(slateLink(_:)):
            return true
        default:
            return super.validateUserInterfaceItem(item)
        }
    }

    func toggle(_ flag: InlineStyle) {
        guard let storage = textStorage else { return }
        let selection = selectedRange()
        if selection.length == 0 {
            var current = InlineStyle(rawValue: typingAttributes[.slateInline] as? Int ?? 0)
            current.formSymmetricDifference(flag)
            var attributes = typingAttributes
            attributes[.slateInline] = current.isEmpty ? nil : current.rawValue
            attributes[.font] = style.font(inline: current, header: isHeader)
            typingAttributes = attributes
            return
        }
        var all = true
        storage.enumerateAttribute(.slateInline, in: selection) { value, _, stop in
            if InlineStyle(rawValue: value as? Int ?? 0).contains(flag) == false {
                all = false
                stop.pointee = true
            }
        }
        let changed = NSMutableAttributedString(attributedString: storage.attributedSubstring(from: selection))
        changed.enumerateAttribute(.slateInline, in: NSRange(location: 0, length: changed.length)) { value, range, _ in
            var inline = InlineStyle(rawValue: value as? Int ?? 0)
            if all { inline.remove(flag) } else { inline.insert(flag) }
            if inline.isEmpty {
                changed.removeAttribute(.slateInline, range: range)
            } else {
                changed.addAttribute(.slateInline, value: inline.rawValue, range: range)
            }
        }
        replaceStyled(selection, with: changed)
        setSelectedRange(selection)
    }

    private func editLink() {
        let selection = selectedRange()
        guard let storage = textStorage else { return }
        let current = selection.length > 0 ? storage.attribute(.slateHref, at: selection.location, effectiveRange: nil) as? String : nil
        let selected = selection.length > 0 ? (storage.string as NSString).substring(with: selection) : ""
        let suggestion = current ?? (selected.looksLikeURL ? selected : PasteboardReader.urlString() ?? "")
        let popover = LinkPopover(url: suggestion, canRemove: current != nil) { [weak self] result in
            guard let self else { return }
            linkPopover = nil
            applyLink(result, to: selection)
            window?.makeFirstResponder(self)
        }
        linkPopover = popover
        let rect = firstRect(forCharacterRange: selection, actualRange: nil)
        let local = window.map { convert($0.convertFromScreen(rect), from: nil) } ?? .zero
        popover.show(relativeTo: local.isEmpty ? NSRect(x: local.minX, y: local.minY, width: 2, height: 16) : local, of: self)
    }

    private func applyLink(_ result: LinkPopover.Result, to range: NSRange) {
        guard let storage = textStorage else { return }
        switch result {
        case .remove:
            guard range.length > 0 else { return }
            let text = NSMutableAttributedString(attributedString: storage.attributedSubstring(from: range))
            text.removeAttribute(.slateHref, range: NSRange(location: 0, length: text.length))
            replaceStyled(range, with: text)
        case .set(let url):
            let href = url.trimmingCharacters(in: .whitespacesAndNewlines)
            guard href.isEmpty == false else { return }
            let text = range.length > 0 ? NSMutableAttributedString(attributedString: storage.attributedSubstring(from: range)) : NSMutableAttributedString(string: href)
            text.addAttribute(.slateHref, value: href, range: NSRange(location: 0, length: text.length))
            replaceStyled(range, with: text)
            setSelectedRange(NSRange(location: range.location + text.length, length: 0))
        }
    }

    private func replaceStyled(_ range: NSRange, with text: NSAttributedString) {
        guard shouldChangeText(in: range, replacementString: text.string) else { return }
        let styled = style.styled(text, header: isHeader, alignment: cellAlignment)
        textStorage?.replaceCharacters(in: range, with: styled)
        didChangeText()
    }
}
