import SwiftUI
import SlateEditor
import SlateUI

struct FormatColorMenu: View {
    let state: EditorStyleState
    let perform: (EditorCommand) -> Void

    @State private var isHovered = false

    var body: some View {
        Menu {
            Section("Highlight") {
                ForEach(FormatBarMapper.highlightChoices(for: state)) { choice in
                    item(choice)
                }
            }
            Section("Text Colour") {
                ForEach(FormatBarMapper.textColorChoices(for: state)) { choice in
                    item(choice)
                }
            }
        } label: {
            VStack(spacing: 1) {
                Image(systemName: "highlighter")
                    .font(.system(size: 13, weight: .medium))
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color(nsColor: FormatBarMapper.colorBarTint(for: state)))
                    .frame(width: 14, height: 3)
            }
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .foregroundStyle(state.highlight != nil || state.textColor != nil ? Color.accentColor : Color.secondary)
        .frame(width: 28, height: 26)
        .background(isHovered ? Theme.hover : .clear, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .disabled(state.canFormatInline == false)
        .opacity(state.canFormatInline ? 1 : 0.4)
        .hint("Highlight and text colour. Yellow  ⇧⌘E")
        .accessibilityLabel("Highlight and text colour")
    }

    private func item(_ choice: FormatColorModel) -> some View {
        Button {
            perform(choice.command)
        } label: {
            if let swatch = choice.swatch {
                Label {
                    Text(choice.isCurrent ? "\(choice.title)  ✓" : choice.title)
                } icon: {
                    Image(nsImage: ColorMenu.image(swatch))
                }
            } else {
                Text(choice.title)
            }
        }
    }
}

#Preview {
    FormatColorMenu(state: EditorStyleState()) { _ in }
        .padding()
}
