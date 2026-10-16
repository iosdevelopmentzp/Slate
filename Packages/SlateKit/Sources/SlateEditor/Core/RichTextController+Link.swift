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

    func editLink() {
        guard currentBlock.kind.keepsLineBreaks == false, currentBlock.kind.isAttachment == false else { return }
        let selection = textView.selectedRange()
        let target = selection.length > 0 ? selection : linkRange(at: selection.location) ?? selection
        let current = target.length > 0 ? storage.attribute(.slateHref, at: target.location, effectiveRange: nil) as? String : nil
        let selected = target.length > 0 ? string.substring(with: target) : ""
        let suggestion = current ?? (selected.looksLikeURL ? selected : PasteboardReader.urlString() ?? "")
        let popover = LinkPopover(url: suggestion, canRemove: current != nil) { [weak self] result in
            guard let self else { return }
            activeLinkPopover = nil
            applyLink(result, to: target)
        }
        activeLinkPopover = popover
        let rect = textView.firstRect(forCharacterRange: target, actualRange: nil)
        let local = textView.window.map { textView.convert($0.convertFromScreen(rect), from: nil) } ?? .zero
        popover.show(relativeTo: local.isEmpty ? NSRect(x: local.minX, y: local.minY, width: 2, height: 16) : local, of: textView)
    }

    func applyLink(_ result: LinkPopover.Result, to range: NSRange) {
        switch result {
        case .remove:
            guard range.length > 0 else { return }
            let text = NSMutableAttributedString(attributedString: storage.attributedSubstring(from: range))
            text.removeAttribute(.slateHref, range: NSRange(location: 0, length: text.length))
            replace(range, with: text, selection: range)
        case .set(let url):
            let href = url.trimmingCharacters(in: .whitespacesAndNewlines)
            guard href.isEmpty == false else { return }
            if range.length == 0 {
                let block = currentBlock
                let inserted = NSAttributedString(string: href, attributes: styler.attributes(block: block, inline: [], href: href))
                replace(range, with: inserted, selection: NSRange(location: range.location + inserted.length, length: 0))
                return
            }
            let text = NSMutableAttributedString(attributedString: storage.attributedSubstring(from: range))
            text.addAttribute(.slateHref, value: href, range: NSRange(location: 0, length: text.length))
            replace(range, with: text, selection: NSRange(location: NSMaxRange(range), length: 0))
        }
    }

    func openLink(at location: Int) -> Bool {
        guard location < storage.length, let href = storage.attribute(.slateHref, at: location, effectiveRange: nil) as? String else { return false }
        if href.hasPrefix(RichText.wikiPrefix) {
            handlers.openLink(.wiki(String(href.dropFirst(RichText.wikiPrefix.count))))
        } else {
            handlers.openLink(.url(href))
        }
        return true
    }
}
