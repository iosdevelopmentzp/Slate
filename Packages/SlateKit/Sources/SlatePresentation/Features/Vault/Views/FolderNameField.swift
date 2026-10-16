import AppKit
import SwiftUI
import SlateUI

struct FolderNameField: View {
    @Binding var name: String
    let icon: String
    let tint: Color
    let onCommit: () -> Void
    let onCancel: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(tint)
                .frame(width: 18)
                .accessibilityHidden(true)
            TextField("Folder name", text: $name)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .onSubmit(onCommit)
                .onExitCommand(perform: onCancel)
                .accessibilityLabel("Folder name")
        }
        .padding(.horizontal, 8)
        .frame(height: 30)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.pillRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.pillRadius, style: .continuous).strokeBorder(Theme.selection.opacity(0.5)))
        .onAppear {
            isFocused = true
            Task { @MainActor in
                NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: nil)
            }
        }
        .onChange(of: isFocused) { wasFocused, focused in
            if wasFocused, focused == false { onCommit() }
        }
    }
}

#Preview("Light") {
    FolderNameField(name: .constant("New folder"), icon: "folder.fill", tint: .blue, onCommit: {}, onCancel: {})
        .padding(8)
        .frame(width: 200)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    FolderNameField(name: .constant("New folder"), icon: "folder.fill", tint: .blue, onCommit: {}, onCancel: {})
        .padding(8)
        .frame(width: 200)
        .preferredColorScheme(.dark)
}
