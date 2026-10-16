import AppKit

package struct EditorConfiguration: Equatable, Sendable {
    package var proseFont: NSFont
    package var codeFont: NSFont
    package var lineHeightMultiple: CGFloat

    package init(proseFont: NSFont, codeFont: NSFont, lineHeightMultiple: CGFloat) {
        self.proseFont = proseFont
        self.codeFont = codeFont
        self.lineHeightMultiple = lineHeightMultiple
    }

    package static let standard = EditorConfiguration(
        proseFont: .systemFont(ofSize: 14),
        codeFont: .monospacedSystemFont(ofSize: 13, weight: .regular),
        lineHeightMultiple: 1.35
    )
}
