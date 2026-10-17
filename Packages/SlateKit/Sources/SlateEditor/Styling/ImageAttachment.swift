import AppKit

nonisolated final class ImageAttachment: NSTextAttachment {
    static let cornerRadius: CGFloat = 8
    static let missingSize = CGSize(width: 220, height: 64)
    static let smallestWidth: CGFloat = 40

    let path: String
    let picture: NSImage?
    let maxHeight: CGFloat
    let borderColor: NSColor
    var width: CGFloat?

    init(path: String, picture: NSImage?, maxHeight: CGFloat, borderColor: NSColor, width: CGFloat? = nil) {
        self.path = path
        self.picture = picture
        self.maxHeight = maxHeight
        self.borderColor = borderColor
        self.width = width
        super.init(data: nil, ofType: nil)
        allowsTextAttachmentView = false
        image = rendered(size: picture?.size ?? Self.missingSize)
    }

    required init?(coder: NSCoder) {
        nil
    }

    func displaySize(width available: CGFloat) -> CGSize {
        guard let picture, picture.size.width > 0, picture.size.height > 0 else { return Self.missingSize }
        if let chosen = self.width {
            let width = max(min(available, chosen), Self.smallestWidth)
            return CGSize(width: width.rounded(), height: (width * picture.size.height / picture.size.width).rounded())
        }
        let width = max(min(available, picture.size.width), Self.smallestWidth)
        var size = CGSize(width: width, height: width * picture.size.height / picture.size.width)
        if size.height > maxHeight {
            size = CGSize(width: maxHeight * picture.size.width / picture.size.height, height: maxHeight)
        }
        return CGSize(width: size.width.rounded(), height: size.height.rounded())
    }

    override func attachmentBounds(for attributes: [NSAttributedString.Key: Any], location: any NSTextLocation, textContainer: NSTextContainer?, proposedLineFragment: CGRect, position: CGPoint) -> CGRect {
        let padding = textContainer?.lineFragmentPadding ?? 5
        let available = (textContainer?.size.width ?? proposedLineFragment.width) - padding * 2
        return CGRect(origin: .zero, size: displaySize(width: available))
    }

    override func image(for bounds: CGRect, attributes: [NSAttributedString.Key: Any], location: any NSTextLocation, textContainer: NSTextContainer?) -> NSImage? {
        rendered(size: bounds.size)
    }

    private func rendered(size: CGSize) -> NSImage {
        let picture = picture
        let borderColor = borderColor
        let name = (path as NSString).lastPathComponent
        return NSImage(size: size, flipped: false) { rect in
            let shape = NSBezierPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), xRadius: Self.cornerRadius, yRadius: Self.cornerRadius)
            if let picture {
                NSGraphicsContext.saveGraphicsState()
                shape.addClip()
                picture.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
                NSGraphicsContext.restoreGraphicsState()
            } else {
                NSColor.quaternaryLabelColor.withAlphaComponent(0.2).setFill()
                shape.fill()
                let label = NSAttributedString(string: "Image not found: \(name)", attributes: [.font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor.secondaryLabelColor])
                let size = label.size()
                label.draw(at: CGPoint(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2))
            }
            borderColor.setStroke()
            shape.lineWidth = 1
            shape.stroke()
            return true
        }
    }
}
