import AppKit

nonisolated final class DividerAttachment: NSTextAttachment {
    static let height: CGFloat = 18

    let color: NSColor

    init(color: NSColor) {
        self.color = color
        super.init(data: nil, ofType: nil)
        allowsTextAttachmentView = false
        image = rendered(size: CGSize(width: 400, height: Self.height))
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func attachmentBounds(for attributes: [NSAttributedString.Key: Any], location: any NSTextLocation, textContainer: NSTextContainer?, proposedLineFragment: CGRect, position: CGPoint) -> CGRect {
        let padding = textContainer?.lineFragmentPadding ?? 5
        let width = (textContainer?.size.width ?? proposedLineFragment.width) - padding * 2 - 2
        return CGRect(x: 0, y: -4, width: max(width, 20), height: Self.height)
    }

    override func image(for bounds: CGRect, attributes: [NSAttributedString.Key: Any], location: any NSTextLocation, textContainer: NSTextContainer?) -> NSImage? {
        rendered(size: bounds.size)
    }

    private func rendered(size: CGSize) -> NSImage {
        let color = color
        return NSImage(size: size, flipped: false) { rect in
            color.setFill()
            NSBezierPath(roundedRect: CGRect(x: rect.minX, y: rect.midY - 0.5, width: rect.width, height: 1), xRadius: 0.5, yRadius: 0.5).fill()
            return true
        }
    }
}
