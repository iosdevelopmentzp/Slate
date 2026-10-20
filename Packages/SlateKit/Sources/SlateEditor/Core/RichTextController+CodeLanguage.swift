import AppKit

extension RichTextController {

    func codeLanguageHit(at point: CGPoint) -> Int? {
        guard let layout = textView.textLayoutManager else { return nil }
        let origin = textView.textContainerOrigin
        let local = CGPoint(x: point.x - origin.x, y: point.y - origin.y)
        guard let fragment = layout.textLayoutFragment(for: local) as? RichLayoutFragment, fragment.languageLabel != nil else { return nil }
        let frame = fragment.layoutFragmentFrame
        let label = fragment.languageLabelRect.offsetBy(dx: frame.minX, dy: frame.minY)
        guard label.insetBy(dx: -4, dy: -4).contains(local) else { return nil }
        return layout.offset(from: layout.documentRange.location, to: fragment.rangeInElement.location)
    }

    func showLanguageMenu(at location: Int, point: CGPoint) {
        let current = block(at: location).language
        let menu = NSMenu(title: "Language")
        let known = CodeLanguage.choices.map { ($0.title, Optional($0.name)) }
        var choices: [(String, String?)] = [(CodeLanguage.plain.title, nil)] + known
        if let current, CodeHighlighter.language(named: current).name == CodeLanguage.plain.name {
            choices.append((current, current))
        }
        let currentName = current.map { CodeHighlighter.language(named: $0).name == CodeLanguage.plain.name ? $0 : CodeHighlighter.language(named: $0).name }
        for (title, fence) in choices {
            let item = NSMenuItem(title: title, action: #selector(RichTextView.slateCodeLanguage(_:)), keyEquivalent: "")
            item.target = textView
            item.representedObject = CodeLanguageChoice(location: location, fence: fence)
            item.state = fence == currentName ? .on : .off
            menu.addItem(item)
        }
        menu.popUp(positioning: nil, at: point, in: textView)
    }

    func setCodeLanguage(at location: Int, fence: String?) {
        guard location < storage.length else { return }
        var block = block(at: location)
        guard block.kind == .monospaced, block.language != fence else { return }
        block.language = fence
        let paragraph = paragraphRange(at: location)
        replace(paragraph, with: retagged(storage.attributedSubstring(from: paragraph), as: block), selection: textView.selectedRange())
    }
}
