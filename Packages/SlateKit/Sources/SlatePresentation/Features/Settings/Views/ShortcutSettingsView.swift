import KeyboardShortcuts
import SwiftUI
import SlateUI

struct ShortcutSettingsView: View {
    var body: some View {
        Form {
            Section {
                KeyboardShortcuts.Recorder("Open Slate", name: .togglePanel)
                KeyboardShortcuts.Recorder("Quick note", name: .capture)
                KeyboardShortcuts.Recorder("New note", name: .newNote)
            } footer: {
                Text("These shortcuts work in every app.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    ShortcutSettingsView()
        .frame(width: 480, height: 300)
}
