import SwiftUI
import SlateUI

struct FolderSettingsView: View {
    @Environment(SettingsStore.self) private var settings

    var body: some View {
        Form {
            Section {
                LabeledContent("Notes folder") {
                    Text(settings.vaultPath)
                        .textSelection(.enabled)
                        .lineLimit(2)
                        .truncationMode(.middle)
                }
                Button("Choose another folder…") { settings.changeVault() }
                Text("Slate reads the new folder and builds its search again. The old folder stays as it is.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    FolderSettingsView()
        .previewEnvironment()
        .frame(width: 480, height: 300)
}
