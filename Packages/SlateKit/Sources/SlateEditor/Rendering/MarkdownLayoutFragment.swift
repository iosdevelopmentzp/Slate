import AppKit

nonisolated final class MarkdownLayoutFragment: NSTextLayoutFragment {
    var decoration: LineDecoration = .rule
    var colors: EditorColors = .system

    override var renderingSurfaceBounds: CGRect {
        var bounds = super.renderingSurfaceBounds
        switch decoration {
        case .codeBlock, .rule, .quote:
            bounds = bounds.union(CGRect(x: -8, y: 0, width: containerWidth + 16, height: layoutFragmentFrame.height))
        case .image(_, let size, _):
            bounds = bounds.union(imageRect(size: size))
        case .checkbox:
            if let rect = checkboxRect { bounds = bounds.union(rect.insetBy(dx: -2, dy: -2)) }
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
        drawForeground(in: context)
        context.restoreGState()
    }

    var checkboxRect: CGRect? {
        guard case .checkbox(_, let location) = decoration, let line = textLineFragments.first else { return nil }
        let start = line.locationForCharacter(at: location)
        let end = line.locationForCharacter(at: location + 3)
        let side = min(max(end.x - start.x, 12), 15)
        let origin = line.typographicBounds.origin
        let midY = origin.y + line.glyphOrigin.y - xHeight(of: line) / 2
        return CGRect(x: origin.x + start.x + (end.x - start.x - side) / 2, y: midY - side / 2, width: side, height: side)
    }

    private func xHeight(of line: NSTextLineFragment) -> CGFloat {
        guard line.attributedString.length > 0, let font = line.attributedString.attribute(.font, at: 0, effectiveRange: nil) as? NSFont else { return 7 }
        return font.xHeight
    }

    private var containerWidth: CGFloat {
        textLayoutManager?.textContainer?.size.width ?? layoutFragmentFrame.width
    }

    private var textBottom: CGFloat {
        textLineFragments.last.map { $0.typographicBounds.maxY } ?? layoutFragmentFrame.height
    }

    var imageFrame: CGRect? {
        guard case .image(_, let size, _) = decoration else { return nil }
        return imageRect(size: size).offsetBy(dx: layoutFragmentFrame.minX, dy: layoutFragmentFrame.minY)
    }

    private func imageRect(size: CGSize) -> CGRect {
        CGRect(x: 0, y: textBottom + 4, width: size.width, height: size.height)
    }

    private func drawBackground(in context: CGContext) {
        switch decoration {
        case .codeBlock(let isFirst, let isLast):
            let rect = CGRect(x: 0, y: 0, width: containerWidth - layoutFragmentFrame.minX * 2, height: layoutFragmentFrame.height)
            let path = roundedPath(rect, radius: 6, top: isFirst, bottom: isLast)
            context.addPath(path)
            context.setFillColor(colors.codeBackground.cgColor)
            context.fillPath()
        case .quote:
            context.setFillColor(colors.quoteBar.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: 3, height: layoutFragmentFrame.height))
        case .rule:
            let y = (layoutFragmentFrame.height / 2).rounded() + 0.5
            context.setStrokeColor(colors.mark.cgColor)
            context.setLineWidth(1)
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: containerWidth, y: y))
            context.strokePath()
        case .checkbox, .image:
            break
        }
    }

    private func drawForeground(in context: CGContext) {
        switch decoration {
        case .checkbox(let isChecked, _):
            guard let rect = checkboxRect else { return }
            drawCheckbox(in: rect, isChecked: isChecked, context: context)
        case .image(let image, let size, _):
            let rect = imageRect(size: size)
            guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }
            context.saveGState()
            context.translateBy(x: rect.minX, y: rect.maxY)
            context.scaleBy(x: 1, y: -1)
            context.addPath(CGPath(roundedRect: CGRect(origin: .zero, size: rect.size), cornerWidth: 4, cornerHeight: 4, transform: nil))
            context.clip()
            context.draw(cgImage, in: CGRect(origin: .zero, size: rect.size))
            context.restoreGState()
        case .codeBlock, .quote, .rule:
            break
        }
    }

    private func drawCheckbox(in rect: CGRect, isChecked: Bool, context: CGContext) {
        let path = CGPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), cornerWidth: 3, cornerHeight: 3, transform: nil)
        if isChecked {
            context.addPath(path)
            context.setFillColor(colors.checkbox.cgColor)
            context.fillPath()
            context.setStrokeColor(NSColor.white.cgColor)
            context.setLineWidth(1.6)
            context.setLineCap(.round)
            context.setLineJoin(.round)
            context.move(to: CGPoint(x: rect.minX + rect.width * 0.25, y: rect.minY + rect.height * 0.52))
            context.addLine(to: CGPoint(x: rect.minX + rect.width * 0.43, y: rect.minY + rect.height * 0.70))
            context.addLine(to: CGPoint(x: rect.minX + rect.width * 0.76, y: rect.minY + rect.height * 0.32))
            context.strokePath()
        } else {
            context.addPath(path)
            context.setStrokeColor(colors.secondaryText.cgColor)
            context.setLineWidth(1)
            context.strokePath()
        }
    }

    private func roundedPath(_ rect: CGRect, radius: CGFloat, top: Bool, bottom: Bool) -> CGPath {
        let path = CGMutablePath()
        let topRadius = top ? radius : 0
        let bottomRadius = bottom ? radius : 0
        path.move(to: CGPoint(x: rect.minX + topRadius, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - topRadius, y: rect.minY))
        path.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.minY), tangent2End: CGPoint(x: rect.maxX, y: rect.minY + topRadius), radius: topRadius)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRadius))
        path.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.maxY), tangent2End: CGPoint(x: rect.maxX - bottomRadius, y: rect.maxY), radius: bottomRadius)
        path.addLine(to: CGPoint(x: rect.minX + bottomRadius, y: rect.maxY))
        path.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.maxY), tangent2End: CGPoint(x: rect.minX, y: rect.maxY - bottomRadius), radius: bottomRadius)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + topRadius))
        path.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.minY), tangent2End: CGPoint(x: rect.minX + topRadius, y: rect.minY), radius: topRadius)
        path.closeSubpath()
        return path
    }
}
