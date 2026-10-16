import Foundation

nonisolated package struct InlineStyle: OptionSet, Hashable, Sendable {
    package let rawValue: Int

    package init(rawValue: Int) {
        self.rawValue = rawValue
    }

    package static let bold = InlineStyle(rawValue: 1 << 0)
    package static let italic = InlineStyle(rawValue: 1 << 1)
    package static let strikethrough = InlineStyle(rawValue: 1 << 2)
    package static let code = InlineStyle(rawValue: 1 << 3)
}
