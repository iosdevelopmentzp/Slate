import SlateEditor
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct FormatBarMapperTests {
    @Test func theStyleMenuNamesTheCurrentStyle() {
        let state = EditorStyleState(kind: .subheading)

        #expect(FormatBarMapper.styleName(for: state) == "Subheading")
        #expect(FormatBarMapper.styles(for: state).map(\.title) == ["Title", "Heading", "Subheading", "Body", "Monospaced"])
        #expect(FormatBarMapper.styles(for: state).filter(\.isCurrent).map(\.id) == [.subheading])
    }

    @Test func activeStylesAreTinted() {
        let state = EditorStyleState(kind: .checklist, inline: [.bold], isLink: true)

        #expect(FormatBarMapper.textButtons(for: state).filter(\.isActive).map(\.id) == ["bold"])
        #expect(FormatBarMapper.blockButtons(for: state).filter(\.isActive).map(\.id) == ["checklist", "link"])
    }

    @Test func codeTurnsTextButtonsOffButKeepsImage() {
        let state = EditorStyleState(kind: .monospaced, canFormatText: false)

        #expect(FormatBarMapper.textButtons(for: state).allSatisfy { $0.isEnabled == false })
        #expect(FormatBarMapper.blockButtons(for: state).filter(\.isEnabled).map(\.id) == ["image"])
    }

    @Test func hintsShowTheShortcut() {
        let hints = (FormatBarMapper.textButtons(for: EditorStyleState()) + FormatBarMapper.blockButtons(for: EditorStyleState())).map(\.hint)

        #expect(hints == ["Bold  ⌘B", "Italic  ⌘I", "Strikethrough  ⇧⌘X", "Checklist  ⇧⌘L", "Bulleted list  ⇧⌘7", "Numbered list  ⇧⌘9", "Quote  ⌘'", "Link  ⌘K", "Image  ⇧⌘I"])
    }
}
