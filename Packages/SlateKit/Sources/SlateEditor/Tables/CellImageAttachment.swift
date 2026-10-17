import AppKit

nonisolated final class CellImageAttachment: NSTextAttachment {
    static let height: CGFloat = 80
    static let radius: CGFloat = 4
    static let missingWidth: CGFloat = 80

    let path: String

    init(path: String, picture: NSImage?, borderColor: NSColor, width: CGFloat? = nil) {
        self.path = path
        super.init(data: nil, ofType: nil)
        allowsTextAttachmentView = false
        let size = Self.size(of: picture, width: width)
        bounds = CGRect(x: 0, y: -4, width: size.width, height: size.height)
        image = Self.rendered(picture, size: size, borderColor: borderColor)
    }

    required init?(coder: NSCoder) {
        nil
    }

    static func size(of picture: NSImage?, width: CGFloat? = nil) -> CGSize {
        guard let picture, picture.size.width > 0, picture.size.height > 0 else { return CGSize(width: width ?? missingWidth, height: height) }
        if let width {
            let chosen = max(width, ImageAttachment.smallestWidth)
            return CGSize(width: chosen.rounded(), height: (chosen * picture.size.height / picture.size.width).rounded())
        }
        return CGSize(width: (height * picture.size.width / picture.size.height).rounded(), height: height)
    }

    private static func rendered(_ picture: NSImage?, size: CGSize, borderColor: NSColor) -> NSImage {
        NSImage(size: size, flipped: false) { rect in
            let shape = NSBezierPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), xRadius: radius, yRadius: radius)
            if let picture {
                NSGraphicsContext.saveGraphicsState()
                shape.addClip()
                picture.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
                NSGraphicsContext.restoreGraphicsState()
            } else {
                NSColor.quaternaryLabelColor.withAlphaComponent(0.2).setFill()
                shape.fill()
            }
            borderColor.setStroke()
            shape.lineWidth = 1
            shape.stroke()
            return true
        }
    }
}
