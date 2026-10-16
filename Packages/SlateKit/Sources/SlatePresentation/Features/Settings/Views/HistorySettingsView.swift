import SwiftUI
import SlateDomain
import SlateUI

struct HistorySettingsView: View {
    @Environment(HistoryStore.self) private var history

    var body: some View {
        @Bindable var history = history
        Form {
            Section {
                Toggle("Keep versions of my notes", isOn: $history.settings.isEnabled)
                Picker("Save a version every", selection: $history.settings.intervalMinutes) {
                    ForEach(HistorySettings.intervals, id: \.self) { minutes in
                        Text("\(minutes) minutes").tag(minutes)
                    }
                }
                .disabled(history.settings.isEnabled == false)
            } footer: {
                Text("Versions are kept with git in Slate's own folder in Application Support, never inside the notes folder. A version is saved only when something changed.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section {
                TextField("Remote", text: $history.settings.remote, prompt: Text("git@gitlab.example.com:me/notes.git"))
                Toggle("Push when Slate quits", isOn: $history.settings.pushOnQuit)
                    .disabled(history.settings.hasRemote == false)
            } header: {
                Text("Backup")
            } footer: {
                Text("With a remote, every version is also pushed there. Use a private repository.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section {
                HStack {
                    if let last = history.lastSnapshot {
                        Text("Last version \(last.relativeDescription(to: .now))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if history.isSnapshotting {
                        ProgressView().controlSize(.small)
                    }
                    Button("Save a version now") { Task { await history.snapshotNow() } }
                        .disabled(history.settings.isEnabled == false || history.isSnapshotting)
                    Button("Save") { history.saveSettings() }
                        .keyboardShortcut(.defaultAction)
                }
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    HistorySettingsView()
        .previewEnvironment()
        .frame(width: 480, height: 420)
}
