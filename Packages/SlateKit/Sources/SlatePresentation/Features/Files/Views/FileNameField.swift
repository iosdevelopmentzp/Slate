import AppKit
import SwiftUI
import SlateUI

struct FileNameField: View {
    @Binding var name: String
    let onCommit: () -> Void
    let onCancel: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        TextField("File name", text: $name)
            .textFieldStyle(.plain)
            .focused($isFocused)
            .onSubmit(onCommit)
            .onExitCommand(perform: onCancel)
            .accessibilityLabel("File name")
            .padding(.horizontal, Theme.cardPadding)
            .frame(height: 44)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous).strokeBorder(Theme.selection.opacity(0.5)))
            .onAppear { isFocused = true }
            .onChange(of: isFocused) { wasFocused, focused in
                if wasFocused, focused == false { onCommit() }
            }
    }
}

#Preview("Light") {
    FileNameField(name: .constant("crash.log"), onCommit: {}, onCancel: {})
        .padding()
        .frame(width: 320)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    FileNameField(name: .constant("crash.log"), onCommit: {}, onCancel: {})
        .padding()
        .frame(width: 320)
        .preferredColorScheme(.dark)
}
