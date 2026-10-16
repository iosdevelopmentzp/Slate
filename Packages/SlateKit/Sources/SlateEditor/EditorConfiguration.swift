import AppKit

package struct EditorConfiguration: Equatable, Sendable {
    package var proseFont: NSFont
    package var codeFont: NSFont
    package var lineHeightMultiple: CGFloat
    package var codeLineHeightMultiple: CGFloat
    package var colors: EditorColors
    package var linkPatterns: [EditorLinkPattern]
    package var imageMaxHeight: CGFloat

    package init(
        proseFont: NSFont,
        codeFont: NSFont,
        lineHeightMultiple: CGFloat,
        codeLineHeightMultiple: CGFloat = 1.2,
        colors: EditorColors = .system,
        linkPatterns: [EditorLinkPattern] = [],
        imageMaxHeight: CGFloat = 360
    ) {
        self.proseFont = proseFont
        self.codeFont = codeFont
        self.lineHeightMultiple = lineHeightMultiple
        self.codeLineHeightMultiple = codeLineHeightMultiple
        self.colors = colors
        self.linkPatterns = linkPatterns
        self.imageMaxHeight = imageMaxHeight
    }

    package static let standard = EditorConfiguration(
        proseFont: .systemFont(ofSize: 14),
        codeFont: .monospacedSystemFont(ofSize: 13, weight: .regular),
        lineHeightMultiple: 1.35
    )
}
