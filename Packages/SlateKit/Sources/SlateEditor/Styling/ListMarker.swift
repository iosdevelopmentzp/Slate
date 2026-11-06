import AppKit

nonisolated enum ListMarker {
    static func rect(lineStart: CGFloat, baseline: CGFloat, fontSize: CGFloat) -> CGRect {
        let side = (fontSize * 1.1).rounded()
        let center = CGPoint(x: lineStart - RichTextStyler.markerWidth / 2 - 2, y: baseline - fontSize * 0.34)
        return CGRect(x: center.x - side / 2, y: center.y - side / 2, width: side, height: side)
    }

    static func draw(_ decoration: ParagraphDecoration, in rect: CGRect, fontSize: CGFloat, colors: EditorColors, context: CGContext) {
        switch decoration {
        case .bullet(let level):
            let symbols = ["•", "◦", "▪"]
            drawText(symbols[min(level, symbols.count - 1)], centeredIn: rect, size: fontSize * (level == 2 ? 0.8 : 1.1), color: colors.secondaryText, in: context)
        case .number(let number):
            let text = NSAttributedString(string: "\(number).", attributes: [.font: NSFont.monospacedDigitSystemFont(ofSize: fontSize, weight: .regular), .foregroundColor: colors.secondaryText])
            let size = text.size()
            draw(text, at: CGPoint(x: rect.maxX + 2 - size.width, y: rect.midY - size.height / 2), in: context)
        case .checkbox(let done):
            let circle = rect.insetBy(dx: 1, dy: 1)
            if done {
                context.setFillColor(colors.accent.cgColor)
                context.fillEllipse(in: circle)
                drawCheck(in: circle, context: context)
            } else {
                context.setStrokeColor(colors.checkboxBorder.cgColor)
                context.setLineWidth(1.5)
                context.strokeEllipse(in: circle.insetBy(dx: 0.75, dy: 0.75))
            }
        default:
            break
        }
    }

    private static func drawCheck(in circle: CGRect, context: CGContext) {
        context.setStrokeColor(NSColor.white.cgColor)
        context.setLineWidth(max(circle.width * 0.12, 1.5))
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.move(to: CGPoint(x: circle.minX + circle.width * 0.28, y: circle.midY))
        context.addLine(to: CGPoint(x: circle.minX + circle.width * 0.44, y: circle.minY + circle.height * 0.66))
        context.addLine(to: CGPoint(x: circle.minX + circle.width * 0.73, y: circle.minY + circle.height * 0.34))
        context.strokePath()
    }

    private static func drawText(_ string: String, centeredIn rect: CGRect, size: CGFloat, color: NSColor, in context: CGContext) {
        let text = NSAttributedString(string: string, attributes: [.font: NSFont.systemFont(ofSize: size), .foregroundColor: color])
        let measured = text.size()
        draw(text, at: CGPoint(x: rect.midX - measured.width / 2, y: rect.midY - measured.height / 2), in: context)
    }

    private static func draw(_ text: NSAttributedString, at point: CGPoint, in context: CGContext) {
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: true)
        text.draw(at: point)
        NSGraphicsContext.restoreGraphicsState()
    }
}
