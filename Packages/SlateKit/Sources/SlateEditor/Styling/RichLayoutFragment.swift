import AppKit

nonisolated final class RichLayoutFragment: NSTextLayoutFragment {
    enum Fold {
        case open
        case closed
    }

    var decoration: ParagraphDecoration = .none
    var fold: Fold?
    var colors: EditorColors = .system
    var fontSize: CGFloat = 15
    var languageLabel: String?

    static var labelFont: NSFont { .systemFont(ofSize: 10, weight: .medium) }

    override var renderingSurfaceBounds: CGRect {
        var bounds = super.renderingSurfaceBounds
        switch decoration {
        case .block:
            bounds = bounds.union(blockRect.insetBy(dx: -1, dy: -1))
        case .quote:
            bounds = bounds.union(quoteRect)
        case .bullet, .number, .checkbox:
            bounds = bounds.union(markerRect.insetBy(dx: -2, dy: -2))
        case .none:
            break
        }
        if fold != nil {
            bounds = bounds.union(foldRect.insetBy(dx: -2, dy: -2))
        }
        return bounds
    }

    override func draw(at point: CGPoint, in context: CGContext) {
        context.saveGState()
        context.translateBy(x: point.x, y: point.y)
        drawBackground(in: context)
        context.restoreGState()
        super.draw(at: point, in: context)
        context.saveGState()
        context.translateBy(x: point.x, y: point.y)
        drawMarker(in: context)
        drawLanguageLabel(in: context)
        drawFold(in: context)
        context.restoreGState()
    }

    var languageLabelRect: CGRect {
        guard let languageLabel, decoration == .block(raw: false) else { return .zero }
        let size = NSAttributedString(string: languageLabel, attributes: [.font: Self.labelFont]).size()
        let block = blockRect
        return CGRect(x: block.maxX - size.width - 14, y: block.minY + 4, width: size.width + 8, height: size.height + 2)
    }

    private func drawLanguageLabel(in context: CGContext) {
        let rect = languageLabelRect
        guard let languageLabel, rect.isEmpty == false else { return }
        context.addPath(CGPath(roundedRect: rect, cornerWidth: 4, cornerHeight: 4, transform: nil))
        context.setFillColor(colors.codeBackground.cgColor)
        context.fillPath()
        let text = NSAttributedString(string: languageLabel, attributes: [.font: Self.labelFont, .foregroundColor: colors.secondaryText])
        draw(text, at: CGPoint(x: rect.minX + 4, y: rect.minY + 1), in: context)
    }

    var foldRect: CGRect {
        guard fold != nil, let line = textLineFragments.first else { return .zero }
        let start = line.typographicBounds.minX + line.locationForCharacter(at: 0).x
        let side: CGFloat = 12
        let center = line.typographicBounds.minY + line.glyphOrigin.y - fontSize * 0.36
        return CGRect(x: start - side - 4, y: center - side / 2, width: side, height: side)
    }

    private func drawFold(in context: CGContext) {
        let rect = foldRect.insetBy(dx: 3, dy: 3)
        guard let fold, rect.isEmpty == false else { return }
        context.setStrokeColor(colors.secondaryText.cgColor)
        context.setLineWidth(1.6)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        switch fold {
        case .closed:
            context.move(to: CGPoint(x: rect.minX + 1.5, y: rect.minY))
            context.addLine(to: CGPoint(x: rect.maxX - 1.5, y: rect.midY))
            context.addLine(to: CGPoint(x: rect.minX + 1.5, y: rect.maxY))
        case .open:
            context.move(to: CGPoint(x: rect.minX, y: rect.minY + 1.5))
            context.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - 1.5))
            context.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + 1.5))
        }
        context.strokePath()
    }

    var markerRect: CGRect {
        guard let line = textLineFragments.first else { return .zero }
        let start = line.typographicBounds.minX + line.locationForCharacter(at: 0).x
        let side = (fontSize * 1.1).rounded()
        let baseline = line.typographicBounds.minY + line.glyphOrigin.y
        let center = CGPoint(x: start - RichTextStyler.markerWidth / 2 - 2, y: baseline - fontSize * 0.34)
        return CGRect(x: center.x - side / 2, y: center.y - side / 2, width: side, height: side)
    }

    private var textBounds: CGRect {
        guard let first = textLineFragments.first, let last = textLineFragments.last else { return .zero }
        return CGRect(x: 0, y: first.typographicBounds.minY, width: containerWidth, height: last.typographicBounds.maxY - first.typographicBounds.minY)
    }

    private var containerWidth: CGFloat {
        textLayoutManager?.textContainer?.size.width ?? layoutFragmentFrame.width
    }

    private var padding: CGFloat {
        textLayoutManager?.textContainer?.lineFragmentPadding ?? 5
    }

    private var blockRect: CGRect {
        let text = textBounds
        return CGRect(x: padding - layoutFragmentFrame.minX, y: text.minY - 6, width: containerWidth - padding * 2, height: text.height + 12)
    }

    private var quoteRect: CGRect {
        let text = textBounds
        return CGRect(x: padding + 2 - layoutFragmentFrame.minX, y: text.minY + 2, width: 3, height: max(text.height - 4, 4))
    }

    private func drawBackground(in context: CGContext) {
        switch decoration {
        case .block(let raw):
            context.addPath(CGPath(roundedRect: blockRect, cornerWidth: 8, cornerHeight: 8, transform: nil))
            context.setFillColor((raw ? colors.rawBackground : colors.codeBackground).cgColor)
            context.fillPath()
        case .quote:
            context.addPath(CGPath(roundedRect: quoteRect, cornerWidth: 1.5, cornerHeight: 1.5, transform: nil))
            context.setFillColor(colors.quoteBar.cgColor)
            context.fillPath()
        default:
            break
        }
    }

    private func drawMarker(in context: CGContext) {
        let rect = markerRect
        guard rect.isEmpty == false else { return }
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

    private func drawCheck(in circle: CGRect, context: CGContext) {
        context.setStrokeColor(NSColor.white.cgColor)
        context.setLineWidth(max(circle.width * 0.12, 1.5))
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.move(to: CGPoint(x: circle.minX + circle.width * 0.28, y: circle.midY))
        context.addLine(to: CGPoint(x: circle.minX + circle.width * 0.44, y: circle.minY + circle.height * 0.66))
        context.addLine(to: CGPoint(x: circle.minX + circle.width * 0.73, y: circle.minY + circle.height * 0.34))
        context.strokePath()
    }

    private func drawText(_ string: String, centeredIn rect: CGRect, size: CGFloat, color: NSColor, in context: CGContext) {
        let text = NSAttributedString(string: string, attributes: [.font: NSFont.systemFont(ofSize: size), .foregroundColor: color])
        let measured = text.size()
        draw(text, at: CGPoint(x: rect.midX - measured.width / 2, y: rect.midY - measured.height / 2), in: context)
    }

    private func draw(_ text: NSAttributedString, at point: CGPoint, in context: CGContext) {
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: true)
        text.draw(at: point)
        NSGraphicsContext.restoreGraphicsState()
    }
}
