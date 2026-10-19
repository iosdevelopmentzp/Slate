import AppKit

final class TableCellEditor: NSTextView {
    weak var table: TableBlockView?
    let cellUndo = UndoManager()
    var style = TableStyle()
    var isHeader = false
    var cellAlignment = TableAlignment.none
    private var linkPopover: LinkPopover?

    var isEditingLink: Bool {
        linkPopover != nil
    }

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
        if window?.firstResponder === self, let action = KeyboardMap.tableMove(for: event), let table, let editing = table.editing {
            table.move(action, at: editing, selection: nil)
            return true
        }
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
        let point = convert(event.locationInWindow, from: nil)
        if event.modifierFlags.contains(.command), let href = href(at: point) {
            table?.host?.openLink(href)
            return
        }
        if event.clickCount == 2, let path = imagePath(at: point) {
            table?.host?.imageAction(path, .quickLook)
            return
        }
        super.mouseDown(with: event)
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        let menu = super.menu(for: event) ?? NSMenu()
        let point = convert(event.locationInWindow, from: nil)
        if let storage = textStorage, href(at: point) != nil {
            let index = min(characterIndexForInsertion(at: point), storage.length - 1)
            let candidates = [index, index - 1].filter { $0 >= 0 && storage.attribute(.slateHref, at: $0, effectiveRange: nil) != nil }
            if let hit = candidates.first {
                var range = NSRange(location: 0, length: 0)
                _ = storage.attribute(.slateHref, at: hit, longestEffectiveRange: &range, in: NSRange(location: 0, length: storage.length))
                LinkMenu.prepend(range: range, target: self, action: #selector(cellLinkAction(_:)), to: menu)
            }
        }
        guard let table, let path = imagePath(at: convert(event.locationInWindow, from: nil)) else { return menu }
        return ImageMenu.prepend(path: path, target: table, action: #selector(TableBlockView.cellImageAction(_:)), size: table.cellImageSizeItem(at: convert(event.locationInWindow, from: nil)), to: menu)
    }

    override func selectAll(_ sender: Any?) {
        let length = (string as NSString).length
        guard let table, selectedRange() == NSRange(location: 0, length: length) else {
            super.selectAll(sender)
            return
        }
        table.selectWholeTable()
    }

    func href(at point: CGPoint) -> String? {
        guard let storage = textStorage, storage.length > 0, let window else { return nil }
        let index = characterIndexForInsertion(at: point)
        let hit = [index, index - 1].first { candidate in
            guard candidate >= 0, candidate < storage.length else { return false }
            let screen = firstRect(forCharacterRange: NSRange(location: candidate, length: 1), actualRange: nil)
            return convert(window.convertFromScreen(screen), from: nil).insetBy(dx: -2, dy: -2).contains(point)
        }
        return hit.flatMap { storage.attribute(.slateHref, at: $0, effectiveRange: nil) as? String }
    }

    func imagePath(at point: CGPoint) -> String? {
        guard let storage = textStorage, let location = imageLocation(at: point) else { return nil }
        return storage.attribute(.slateImagePath, at: location, effectiveRange: nil) as? String
    }

    func imageLocation(at point: CGPoint) -> Int? {
        guard let storage = textStorage, storage.length > 0 else { return nil }
        let index = characterIndexForInsertion(at: point)
        return [index, index - 1].first { $0 >= 0 && $0 < storage.length && storage.attribute(.slateImagePath, at: $0, effectiveRange: nil) != nil }
    }

    func imageOrdinal(of location: Int) -> Int {
        guard let storage = textStorage else { return 0 }
        var count = 0
        storage.enumerateAttribute(.slateImagePath, in: NSRange(location: 0, length: min(location, storage.length))) { value, range, _ in
            if value != nil { count += range.length }
        }
        return count
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
        case #selector(undo(_:)), #selector(redo(_:)), #selector(slateBold(_:)), #selector(slateItalic(_:)), #selector(slateStrikethrough(_:)), #selector(slateCode(_:)), #selector(slateLink(_:)), #selector(cellLinkAction(_:)):
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

    private func editLink(in target: NSRange? = nil) {
        guard let storage = textStorage else { return }
        let selection = selectedRange()
        let range = target ?? (selection.length > 0 ? selection : linkRange(at: selection.location) ?? selection)
        let current = range.length > 0 ? storage.attribute(.slateHref, at: range.location, effectiveRange: nil) as? String : nil
        let selected = range.length > 0 ? (storage.string as NSString).substring(with: range) : ""
        let suggestion = current == nil && selected.looksLikeURL ? selected : PasteboardReader.urlString() ?? ""
        let popover = LinkPopover(text: LinkAddress.editableText(selected), href: current, suggestion: suggestion) { [weak self] result in
            guard let self else { return }
            linkPopover = nil
            applyLink(result, to: range)
            window?.makeFirstResponder(self)
        }
        linkPopover = popover
        let host = table?.host
        Task { @MainActor [weak popover] in
            let names = await host?.linkNotes() ?? []
            popover?.setNotes(names)
        }
        let rect = firstRect(forCharacterRange: range, actualRange: nil)
        let local = window.map { convert($0.convertFromScreen(rect), from: nil) } ?? .zero
        popover.show(relativeTo: local.isEmpty ? NSRect(x: local.minX, y: local.minY, width: 2, height: 16) : local, of: self)
    }

    private func linkRange(at location: Int) -> NSRange? {
        guard let storage = textStorage, storage.length > 0 else { return nil }
        let whole = NSRange(location: 0, length: storage.length)
        var range = NSRange(location: 0, length: 0)
        for index in [min(location, storage.length - 1), location - 1] where index >= 0 {
            if storage.attribute(.slateHref, at: index, longestEffectiveRange: &range, in: whole) != nil {
                return range
            }
        }
        return nil
    }

    private func applyLink(_ result: LinkPopover.Result, to range: NSRange) {
        guard let storage = textStorage else { return }
        switch result {
        case .cancel:
            return
        case .remove:
            guard range.length > 0 else { return }
            let text = NSMutableAttributedString(attributedString: storage.attributedSubstring(from: range))
            text.removeAttribute(.slateHref, range: NSRange(location: 0, length: text.length))
            replaceStyled(range, with: text)
        case .set(let label, let href):
            let current = range.length > 0 ? (storage.string as NSString).substring(with: range) : ""
            let text: NSMutableAttributedString
            if range.length > 0, label == nil || label == current {
                text = NSMutableAttributedString(attributedString: storage.attributedSubstring(from: range))
            } else {
                let attributes = range.length > 0 ? storage.attributes(at: range.location, effectiveRange: nil) : typingAttributes
                text = NSMutableAttributedString(string: label ?? LinkAddress.display(href), attributes: attributes)
            }
            text.addAttribute(.slateHref, value: href, range: NSRange(location: 0, length: text.length))
            replaceStyled(range, with: text)
            setSelectedRange(NSRange(location: range.location + text.length, length: 0))
        }
    }

    @objc func cellLinkAction(_ sender: NSMenuItem) {
        guard let action = LinkAction(rawValue: sender.tag), let range = (sender.representedObject as? NSValue)?.rangeValue,
              let storage = textStorage, NSMaxRange(range) <= storage.length,
              let href = storage.attribute(.slateHref, at: range.location, effectiveRange: nil) as? String else { return }
        switch action {
        case .open:
            table?.host?.openLink(href)
        case .edit:
            editLink(in: range)
        case .copy:
            PasteboardBridge.general.clearContents()
            PasteboardBridge.general.setString(LinkAddress.copyText(href), forType: .string)
        case .remove:
            applyLink(.remove, to: range)
        }
    }

    private func replaceStyled(_ range: NSRange, with text: NSAttributedString) {
        guard shouldChangeText(in: range, replacementString: text.string) else { return }
        let styled = style.styled(text, header: isHeader, alignment: cellAlignment)
        textStorage?.replaceCharacters(in: range, with: styled)
        didChangeText()
    }
}
