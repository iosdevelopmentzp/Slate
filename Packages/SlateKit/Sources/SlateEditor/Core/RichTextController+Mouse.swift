import AppKit

extension RichTextController {

    func handleMouseDown(_ event: NSEvent) -> Bool {
        let point = textView.convert(event.locationInWindow, from: nil)
        if let location = checkboxHit(at: point) {
            toggleCheckbox(at: location)
            return true
        }
        let index = characterIndex(at: point)
        if event.modifierFlags.contains(.command), let index, openLink(at: index) {
            return true
        }
        if event.clickCount == 2, let index, let path = imagePath(at: index) {
            handlers.attachment(path, .quickLook)
            return true
        }
        return false
    }

    private func characterIndex(at point: CGPoint) -> Int? {
        let index = textView.characterIndexForInsertion(at: point)
        guard storage.length > 0 else { return nil }
        let candidates = [index, index - 1].filter { $0 >= 0 && $0 < storage.length }
        return candidates.first { candidate in
            let rect = textView.firstRect(forCharacterRange: NSRange(location: candidate, length: 1), actualRange: nil)
            guard let window = textView.window else { return false }
            let local = textView.convert(window.convertFromScreen(rect), from: nil)
            return local.insetBy(dx: -2, dy: -2).contains(point)
        }
    }

    func imagePath(at index: Int) -> String? {
        guard index < storage.length else { return nil }
        let block = BlockAttributes(storage.attributes(at: index, effectiveRange: nil))
        return block.kind == .image ? block.imagePath : nil
    }

    private func checkboxHit(at point: CGPoint) -> Int? {
        guard let textLayout = textView.textLayoutManager, let contentManager = textLayout.textContentManager else { return nil }
        let origin = textView.textContainerOrigin
        let local = CGPoint(x: point.x - origin.x, y: point.y - origin.y)
        guard let fragment = textLayout.textLayoutFragment(for: local) as? RichLayoutFragment, case .checkbox = fragment.decoration else { return nil }
        let marker = fragment.markerRect.offsetBy(dx: fragment.layoutFragmentFrame.minX, dy: fragment.layoutFragmentFrame.minY).insetBy(dx: -4, dy: -4)
        guard marker.contains(local), let start = fragment.textElement?.elementRange?.location else { return nil }
        return contentManager.offset(from: contentManager.documentRange.location, to: start)
    }

    func imageMenu(at index: Int) -> NSMenu? {
        let candidates = [index, index - 1].filter { $0 >= 0 }
        guard let path = candidates.lazy.compactMap({ self.imagePath(at: $0) }).first else { return nil }
        let menu = NSMenu()
        let items: [(String, AttachmentAction)] = [("Quick Look", .quickLook), ("Open", .open), ("Show in Finder", .reveal), ("Copy Image", .copyImage)]
        for (title, action) in items {
            let item = NSMenuItem(title: title, action: #selector(RichTextView.slateImageAction(_:)), keyEquivalent: "")
            item.representedObject = ImageMenuChoice(path: path, action: action)
            item.target = textView
            menu.addItem(item)
        }
        return menu
    }
}
