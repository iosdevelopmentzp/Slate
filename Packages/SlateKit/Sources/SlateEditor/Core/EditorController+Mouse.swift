import AppKit

extension EditorController {
    func handleMouseDown(at point: NSPoint, event: NSEvent) -> Bool {
        if let fragment = fragment(at: point) {
            let containerPoint = containerPoint(for: point)
            if let box = fragment.checkboxRect {
                let hit = box.offsetBy(dx: fragment.layoutFragmentFrame.minX, dy: fragment.layoutFragmentFrame.minY).insetBy(dx: -3, dy: -3)
                if hit.contains(containerPoint) {
                    toggleCheckbox(lineAt: location(of: fragment))
                    return true
                }
            }
            if let frame = fragment.imageFrame, frame.contains(containerPoint), case .image(_, _, let source) = fragment.decoration {
                if event.clickCount >= 2 {
                    handlers.attachment(source, .quickLook)
                }
                return true
            }
        }
        if event.modifierFlags.contains(.command) {
            let index = textView.characterIndexForInsertion(at: point)
            if let link = link(at: index) {
                handlers.openLink(link)
                return true
            }
        }
        if event.clickCount == 2 {
            let index = textView.characterIndexForInsertion(at: point)
            if case .url(let target) = link(at: index), target.contains("_attachments/") {
                handlers.attachment(target, .open)
                return true
            }
        }
        return false
    }

    func contextMenu(at point: NSPoint) -> NSMenu? {
        guard let fragment = fragment(at: point), let frame = fragment.imageFrame, frame.contains(containerPoint(for: point)),
              case .image(_, _, let source) = fragment.decoration else { return nil }
        let menu = NSMenu()
        menu.addItem(action("Open", source: source, action: .open))
        menu.addItem(action("Quick Look", source: source, action: .quickLook))
        menu.addItem(action("Show in Finder", source: source, action: .reveal))
        menu.addItem(action("Copy Image", source: source, action: .copyImage))
        menu.addItem(.separator())
        let remove = NSMenuItem(title: "Remove Image", action: #selector(removeImageLine(_:)), keyEquivalent: "")
        remove.target = self
        remove.representedObject = location(of: fragment)
        menu.addItem(remove)
        return menu
    }

    func mouseMoved(to point: NSPoint) {
        guard let fragment = fragment(at: point), case .codeBlock = fragment.decoration else {
            copyButton.isHidden = true
            return
        }
        let line = tracker.lineIndex(containing: location(of: fragment))
        guard let block = codeBlock(containingLine: line),
              let textLayout = textView.textLayoutManager,
              let contentStorage = textView.textContentStorage,
              let start = contentStorage.location(contentStorage.documentRange.location, offsetBy: tracker.lines[block.open].start),
              let first = textLayout.textLayoutFragment(for: start) else {
            copyButton.isHidden = true
            return
        }
        let origin = textView.textContainerOrigin
        let width = textLayout.textContainer?.size.width ?? textView.bounds.width
        let frame = first.layoutFragmentFrame
        copyButton.setFrameOrigin(NSPoint(x: origin.x + width - copyButton.frame.width - frame.minX - 4, y: origin.y + frame.minY + 2))
        copyButton.blockRange = block.content
        copyButton.isHidden = false
    }

    func mouseExited() {
        copyButton.isHidden = true
    }

    @objc private func removeImageLine(_ sender: NSMenuItem) {
        guard let location = sender.representedObject as? Int else { return }
        let line = tracker.state(at: location)
        let full = nsText.lineRange(for: line.range)
        textView.apply(TextEdit(range: full, replacement: "", selection: NSRange(location: full.location, length: 0)))
    }

    @objc private func attachmentAction(_ sender: NSMenuItem) {
        guard let pair = sender.representedObject as? AttachmentRequest else { return }
        handlers.attachment(pair.source, pair.action)
    }

    private func action(_ title: String, source: String, action: AttachmentAction) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: #selector(attachmentAction(_:)), keyEquivalent: "")
        item.target = self
        item.representedObject = AttachmentRequest(source: source, action: action)
        return item
    }

    private func fragment(at point: NSPoint) -> MarkdownLayoutFragment? {
        textView.textLayoutManager?.textLayoutFragment(for: containerPoint(for: point)) as? MarkdownLayoutFragment
    }

    private func containerPoint(for point: NSPoint) -> CGPoint {
        let origin = textView.textContainerOrigin
        return CGPoint(x: point.x - origin.x, y: point.y - origin.y)
    }

    private func location(of fragment: NSTextLayoutFragment) -> Int {
        guard let contentStorage = textView.textContentStorage else { return 0 }
        return contentStorage.offset(from: contentStorage.documentRange.location, to: fragment.rangeInElement.location)
    }
}

private final class AttachmentRequest: NSObject {
    let source: String
    let action: AttachmentAction

    init(source: String, action: AttachmentAction) {
        self.source = source
        self.action = action
    }
}
