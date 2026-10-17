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
            characterRect(candidate)?.insetBy(dx: -2, dy: -2).contains(point) == true
        }
    }

    private func characterRect(_ index: Int) -> CGRect? {
        guard let window = textView.window else { return nil }
        let rect = textView.firstRect(forCharacterRange: NSRange(location: index, length: 1), actualRange: nil)
        return textView.convert(window.convertFromScreen(rect), from: nil)
    }

    func setImageWidth(at location: Int, width: Int?) {
        guard location < storage.length, imagePath(at: location) != nil else { return }
        var block = BlockAttributes(storage.attributes(at: location, effectiveRange: nil))
        block.imageAlt = ImageSize.alt(block.imageAlt, width: width)
        let range = NSRange(location: location, length: 1)
        let text = NSMutableAttributedString(attributedString: retagged(storage.attributedSubstring(from: range), as: block))
        text.removeAttribute(.slateImageAlt, range: NSRange(location: 0, length: text.length))
        if let alt = block.imageAlt { text.addAttribute(.slateImageAlt, value: alt, range: NSRange(location: 0, length: text.length)) }
        restyle(text, range: NSRange(location: 0, length: text.length))
        replace(range, with: text, selection: textView.selectedRange())
    }

    func hoverImage(at point: CGPoint?) {
        guard imageHandle.isDragging == false else { return }
        guard let point, let index = characterIndex(at: point), let path = imagePath(at: index),
              (storage.attribute(.attachment, at: index, effectiveRange: nil) as? ImageAttachment)?.picture != nil,
              let rect = characterRect(index) else {
            imageButton.hide()
            imageHandle.hide()
            return
        }
        imageButton.show(path: path, over: rect, in: textView)
        imageHandle.show(location: index, over: rect, in: textView)
    }

    func previewImageWidth(at location: Int, width: CGFloat) {
        guard location < storage.length, let image = storage.attribute(.attachment, at: location, effectiveRange: nil) as? ImageAttachment,
              let textLayout = textView.textLayoutManager, let content = textLayout.textContentManager,
              let start = content.location(content.documentRange.location, offsetBy: location),
              let end = content.location(start, offsetBy: 1),
              let range = NSTextRange(location: start, end: end)
        else { return }
        image.width = width
        textLayout.invalidateLayout(for: range)
        textLayout.textViewportLayoutController.layoutViewport()
        guard let rect = characterRect(location) else { return }
        imageButton.show(path: image.path, over: rect, in: textView)
        imageHandle.place(over: rect, in: textView)
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
        guard let location = candidates.first(where: { self.imagePath(at: $0) != nil }), let path = imagePath(at: location) else { return nil }
        let menu = NSMenu()
        ImageMenu.items(path: path, target: textView, action: #selector(RichTextView.slateImageAction(_:))).forEach(menu.addItem)
        let current = ImageSize.width(in: BlockAttributes(storage.attributes(at: location, effectiveRange: nil)).imageAlt)
        menu.addItem(ImageMenu.sizeItem(ImageMenu.textSizes, current: current, target: textView, action: #selector(RichTextView.slateImageSize(_:))) { ImageSizeChoice(location: location, width: $0) })
        return menu
    }
}
