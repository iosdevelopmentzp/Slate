import AppKit
import SwiftUI

package enum ColorDot {

    package static func image(_ color: NSColor, side: CGFloat = 12) -> Image {
        let image = NSImage(size: NSSize(width: side, height: side), flipped: false) { rect in
            color.setFill()
            NSBezierPath(ovalIn: rect.insetBy(dx: 1, dy: 1)).fill()
            return true
        }
        image.isTemplate = false
        return Image(nsImage: image)
    }
}
