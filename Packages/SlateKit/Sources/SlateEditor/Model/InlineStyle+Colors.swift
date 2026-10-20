import Foundation

extension InlineStyle {
    nonisolated static let formatting = InlineStyle(rawValue: 0xFF)
    nonisolated static let flags: [InlineStyle] = [.bold, .italic, .strikethrough]
    nonisolated private static let highlightShift = 8
    nonisolated private static let textColorShift = 12
    nonisolated private static let fieldMask = 0xF

    nonisolated package var highlight: HighlightColor? {
        get { HighlightColor(rawValue: field(at: Self.highlightShift)) }
        set { setField(newValue?.rawValue ?? 0, at: Self.highlightShift) }
    }

    nonisolated package var textColor: TextColor? {
        get { TextColor(rawValue: field(at: Self.textColorShift)) }
        set { setField(newValue?.rawValue ?? 0, at: Self.textColorShift) }
    }

    nonisolated var formattingOnly: InlineStyle {
        intersection(Self.formatting)
    }

    nonisolated private func field(at shift: Int) -> Int {
        (rawValue >> shift) & Self.fieldMask
    }

    nonisolated private mutating func setField(_ value: Int, at shift: Int) {
        self = InlineStyle(rawValue: (rawValue & ~(Self.fieldMask << shift)) | ((value & Self.fieldMask) << shift))
    }
}
