import AppKit

extension RichTextController {

    func linkRange(at location: Int) -> NSRange? {
        guard storage.length > 0 else { return nil }
        let index = min(location, storage.length - 1)
        var range = NSRange(location: 0, length: 0)
        if storage.attribute(.slateHref, at: index, longestEffectiveRange: &range, in: NSRange(location: 0, length: storage.length)) != nil {
            return range
        }
        if index > 0, storage.attribute(.slateHref, at: index - 1, longestEffectiveRange: &range, in: NSRange(location: 0, length: storage.length)) != nil {
            return range
        }
        return nil
    }

    func editLink(in target: NSRange? = nil) {
        guard currentBlock.kind.keepsLineBreaks == false, currentBlock.kind.isAttachment == false else { return }
        linkBar.hide()
        let selection = textView.selectedRange()
        let range = target ?? (selection.length > 0 ? selection : linkRange(at: selection.location) ?? selection)
        let current = range.length > 0 ? storage.attribute(.slateHref, at: range.location, effectiveRange: nil) as? String : nil
        let selected = range.length > 0 ? string.substring(with: range) : ""
        let suggestion = current == nil && selected.looksLikeURL ? selected : PasteboardReader.urlString() ?? ""
        let popover = LinkPopover(text: LinkAddress.editableText(selected), href: current, suggestion: suggestion) { [weak self] result in
            guard let self else { return }
            activeLinkPopover = nil
            applyLink(result, to: range)
            textView.window?.makeFirstResponder(textView)
            updateLinkBar()
        }
        activeLinkPopover = popover
        let load = handlers.noteNames
        Task { @MainActor [weak popover] in
            let names = await load()
            popover?.setNotes(names)
        }
        let rect = textView.firstRect(forCharacterRange: range, actualRange: nil)
        let local = textView.window.map { textView.convert($0.convertFromScreen(rect), from: nil) } ?? .zero
        popover.show(relativeTo: local.isEmpty ? NSRect(x: local.minX, y: local.minY, width: 2, height: 16) : local, of: textView)
    }

    func applyLink(_ result: LinkPopover.Result, to range: NSRange) {
        switch result {
        case .cancel:
            return
        case .remove:
            guard range.length > 0 else { return }
            let text = NSMutableAttributedString(attributedString: storage.attributedSubstring(from: range))
            text.removeAttribute(.slateHref, range: NSRange(location: 0, length: text.length))
            replace(range, with: text, selection: range)
        case .set(let label, let href):
            let current = range.length > 0 ? string.substring(with: range) : ""
            if range.length > 0, label == nil || label == current {
                let text = NSMutableAttributedString(attributedString: storage.attributedSubstring(from: range))
                text.addAttribute(.slateHref, value: href, range: NSRange(location: 0, length: text.length))
                replace(range, with: text, selection: NSRange(location: NSMaxRange(range), length: 0))
                return
            }
            let inserted = NSAttributedString(string: label ?? LinkAddress.display(href), attributes: linkAttributes(at: range, href: href))
            replace(range, with: inserted, selection: NSRange(location: range.location + inserted.length, length: 0))
        }
    }

    private func linkAttributes(at range: NSRange, href: String) -> [NSAttributedString.Key: Any] {
        guard range.length > 0 else { return styler.attributes(block: currentBlock, inline: [], href: href) }
        let attributes = storage.attributes(at: range.location, effectiveRange: nil)
        let inline = InlineStyle(rawValue: attributes[.slateInline] as? Int ?? 0)
        return styler.attributes(block: BlockAttributes(attributes), inline: inline, href: href)
    }

    func updateLinkBar() {
        let selection = textView.selectedRange()
        guard selection.length == 0, activeLinkPopover == nil, multiCaret.isActive == false,
              let window = textView.window, window.firstResponder === textView,
              let range = linkRange(at: selection.location),
              let href = storage.attribute(.slateHref, at: range.location, effectiveRange: nil) as? String else {
            linkBar.hide()
            return
        }
        let screen = textView.firstRect(forCharacterRange: range, actualRange: nil)
        linkBar.show(href: href, range: range, below: textView.convert(window.convertFromScreen(screen), from: nil), in: textView)
    }

    func performLinkAction(_ action: LinkAction, range: NSRange) {
        guard range.length > 0, NSMaxRange(range) <= storage.length,
              let href = storage.attribute(.slateHref, at: range.location, effectiveRange: nil) as? String else { return }
        switch action {
        case .open:
            openLink(href)
        case .edit:
            editLink(in: range)
        case .copy:
            PasteboardBridge.general.clearContents()
            PasteboardBridge.general.setString(LinkAddress.copyText(href), forType: .string)
            handlers.notice("Copied the link address")
        case .remove:
            applyLink(.remove, to: range)
            updateLinkBar()
        }
    }

    func linkMenu(at index: Int, adding menu: NSMenu) -> NSMenu? {
        guard index >= 0, index < storage.length else { return nil }
        var range = NSRange(location: 0, length: 0)
        guard storage.attribute(.slateHref, at: index, longestEffectiveRange: &range, in: NSRange(location: 0, length: storage.length)) != nil else { return nil }
        LinkMenu.prepend(range: range, target: textView, action: #selector(RichTextView.slateLinkAction(_:)), to: menu)
        return menu
    }

    func openLink(at location: Int) -> Bool {
        guard location < storage.length, let href = storage.attribute(.slateHref, at: location, effectiveRange: nil) as? String else { return false }
        openLink(href)
        return true
    }

    func openLink(_ href: String) {
        if href.hasPrefix(RichText.wikiPrefix) {
            handlers.openLink(.wiki(String(href.dropFirst(RichText.wikiPrefix.count))))
        } else {
            handlers.openLink(.url(href))
        }
    }

    func linkNotes() async -> [String] {
        await handlers.noteNames()
    }
}
