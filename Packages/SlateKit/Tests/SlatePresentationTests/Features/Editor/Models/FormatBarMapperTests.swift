import SlateEditor
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct FormatBarMapperTests {
    @Test func theStyleMenuNamesTheCurrentStyle() {
        let state = EditorStyleState(kind: .subheading)

        #expect(FormatBarMapper.styleName(for: state) == "Subheading")
        #expect(FormatBarMapper.styles(for: state).map(\.title) == ["Title", "Heading", "Subheading", "Body", "Code block"])
        #expect(FormatBarMapper.styles(for: state).filter(\.isCurrent).map(\.id) == [.subheading])
    }

    @Test func activeStylesAreTinted() {
        let state = EditorStyleState(kind: .checklist, inline: [.bold], isLink: true)

        #expect(FormatBarMapper.textButtons(for: state).filter(\.isActive).map(\.id) == ["bold"])
        #expect(FormatBarMapper.blockButtons(for: state).filter(\.isActive).map(\.id) == ["checklist", "link"])
    }

    @Test func codeTurnsTextButtonsOffButKeepsCodeImageFileAndTable() {
        let state = EditorStyleState(kind: .monospaced, canFormatText: false)

        #expect(FormatBarMapper.textButtons(for: state).allSatisfy { $0.isEnabled == false })
        #expect(FormatBarMapper.blockButtons(for: state).filter(\.isEnabled).map(\.id) == ["code", "image", "file", "table"])
        #expect(FormatBarMapper.blockButtons(for: state).filter(\.isActive).map(\.id) == ["code"])
    }

    @Test func hintsShowTheShortcut() {
        let hints = (FormatBarMapper.textButtons(for: EditorStyleState()) + FormatBarMapper.blockButtons(for: EditorStyleState())).map(\.hint)

        #expect(hints == ["Bold  ⌘B", "Italic  ⌘I", "Strikethrough  ⇧⌘X", "Checklist  ⇧⌘L", "Bulleted list  ⇧⌘7", "Numbered list  ⇧⌘9", "Quote  ⌘'", "Code block  ⇧⌘M", "Link  ⌘K", "Image  ⇧⌘I", "Attach file  ⇧⌘A", "Table  ⌥⌘T"])
    }

    @Test func moreButtonsHoldDividerScreenshotAndFormatJSON() {
        let models = FormatBarMapper.moreButtons(for: EditorStyleState(kind: .monospaced, canFormatText: false))

        #expect(models.map(\.command) == [.divider, .screenshot, .formatJSON])
        #expect(models.map(\.hint) == ["Divider", "Screenshot  ⇧⌘S", "Format JSON  ⌥⇧⌘J"])
        #expect(models.allSatisfy { $0.isEnabled })
    }

    @Test func inATableCellTheTextButtonsAndLinkWork() {
        let state = EditorStyleState(kind: .table, canFormatText: false, isInCell: true)

        #expect(FormatBarMapper.textButtons(for: state).allSatisfy { $0.isEnabled })
        #expect(FormatBarMapper.blockButtons(for: state).filter(\.isEnabled).map(\.id) == ["link", "image", "file", "table"])
    }

    @Test func theColourMenuMarksTheCurrentColours() {
        var inline = InlineStyle.bold
        inline.highlight = .green
        inline.textColor = .red
        let state = EditorStyleState(inline: inline)

        #expect(FormatBarMapper.highlightChoices(for: state).map(\.title) == ["Yellow", "Green", "Blue", "Pink", "Purple", "Remove Highlight"])
        #expect(FormatBarMapper.highlightChoices(for: state).filter(\.isCurrent).map(\.command) == [.highlight(.green)])
        #expect(FormatBarMapper.textColorChoices(for: state).map(\.title) == ["Red", "Orange", "Green", "Blue", "Grey", "Default Colour"])
        #expect(FormatBarMapper.textColorChoices(for: state).filter(\.isCurrent).map(\.command) == [.textColor(.red)])
        #expect(FormatBarMapper.colorBarTint(for: state) == HighlightColor.green.swatch)
    }

    @Test func theColourBarIsYellowWithoutAColour() {
        #expect(FormatBarMapper.colorBarTint(for: EditorStyleState()) == HighlightColor.yellow.swatch)
    }
}
