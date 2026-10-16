import SwiftUI

package struct SearchField: View {
    package let prompt: String
    @Binding package var text: String
    package var focus: FocusState<Bool>.Binding?

    package init(prompt: String, text: Binding<String>, focus: FocusState<Bool>.Binding? = nil) {
        self.prompt = prompt
        self._text = text
        self.focus = focus
    }

    package var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            field
                .textFieldStyle(.plain)
                .onExitCommand { text = "" }
            if text.isEmpty == false {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .font(.body)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.pillRadius, style: .continuous))
    }

    @ViewBuilder
    private var field: some View {
        if let focus {
            TextField(prompt, text: $text)
                .focused(focus)
        } else {
            TextField(prompt, text: $text)
        }
    }
}
