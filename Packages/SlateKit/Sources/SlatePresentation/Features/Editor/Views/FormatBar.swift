import SwiftUI
import SlateEditor
import SlateUI

struct FormatBar: View {
    let commands: EditorCommands

    static let height: CGFloat = 36

    var body: some View {
        let state = commands.state
        ViewThatFits(in: .horizontal) {
            buttons(for: state, showsMore: true)
            buttons(for: state, showsMore: false)
        }
        .padding(.horizontal, 6)
        .frame(height: Self.height)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous).strokeBorder(Theme.border.opacity(0.6)))
        .shadow(color: Theme.shadow, radius: 4, y: 1)
    }

    private func buttons(for state: EditorStyleState, showsMore: Bool) -> some View {
        HStack(spacing: 2) {
            styleMenu(for: state)
            gap
            group(FormatBarMapper.textButtons(for: state))
            gap
            group(FormatBarMapper.blockButtons(for: state))
            if showsMore {
                gap
                group(FormatBarMapper.moreButtons(for: state))
            } else {
                moreMenu(for: state)
            }
        }
        .fixedSize()
    }

    private func group(_ models: [FormatButtonModel]) -> some View {
        ForEach(models) { model in
            FormatButton(model: model) { commands.perform(model.command) }
        }
    }

    private func moreMenu(for state: EditorStyleState) -> some View {
        Menu {
            ForEach(FormatBarMapper.moreButtons(for: state)) { model in
                Button(model.hint) { commands.perform(model.command) }
            }
        } label: {
            Image(systemName: "ellipsis")
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .foregroundStyle(.secondary)
        .frame(width: 28, height: 26)
        .hint("More")
        .accessibilityLabel("More")
    }

    private func styleMenu(for state: EditorStyleState) -> some View {
        Menu {
            ForEach(FormatBarMapper.styles(for: state)) { style in
                Toggle(isOn: Binding(get: { style.isCurrent }, set: { _ in commands.perform(.style(style.id)) })) {
                    Text("\(style.title)  \(style.shortcut)")
                }
            }
        } label: {
            Text(FormatBarMapper.styleName(for: state))
                .font(.system(size: 13, weight: .medium))
                .frame(minWidth: 96, alignment: .leading)
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .frame(height: 26)
        .background(Theme.hover, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        .disabled(state.canFormatText == false && state.kind != .monospaced)
        .hint("Paragraph style")
        .accessibilityLabel("Paragraph style")
    }

    private var gap: some View {
        Divider()
            .frame(height: 16)
            .padding(.horizontal, 6)
    }
}

#Preview {
    FormatBar(commands: EditorCommands())
        .padding()
}
