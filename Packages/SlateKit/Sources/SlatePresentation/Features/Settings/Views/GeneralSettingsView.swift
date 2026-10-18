import SwiftUI
import SlateDomain
import SlateUI

struct GeneralSettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(VaultStore.self) private var vault
    @Environment(HistoryStore.self) private var history
    @State private var showsActivity = false
    @State private var remote = ""

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section {
                LabeledContent("Notes folder") {
                    Text(settings.vaultPath)
                        .textSelection(.enabled)
                        .lineLimit(2)
                        .truncationMode(.middle)
                }
                Button("Choose another folder…") { settings.changeVault() }
            }
            Section {
                Toggle("Open Slate at login", isOn: Binding(
                    get: { settings.loginStatus == .enabled || settings.loginStatus == .requiresApproval },
                    set: { enabled in Task { await settings.setLaunchAtLogin(enabled) } }
                ))
                if let hint = settings.loginHint {
                    Text(hint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Picker("Quick notes go to", selection: Binding(
                    get: { vault.config.captureSpace },
                    set: { space in Task { await vault.setCaptureSpace(space) } }
                )) {
                    ForEach(vault.spaces) { space in
                        Text(space.folder.rawValue).tag(space.folder)
                    }
                }
            }
            Section {
                Picker("Appearance", selection: $settings.appearance) {
                    ForEach(AppAppearance.allCases) { appearance in
                        Text(appearance.title).tag(appearance)
                    }
                }
                Picker("Text size", selection: $settings.editorFontSize) {
                    ForEach(SettingsStore.fontSizes, id: \.self) { size in
                        Text("\(size) pt").tag(size)
                    }
                }
            }
            Section {
                TextField("Back up to", text: $remote, prompt: Text("git@example.com:me/notes.git"))
                    .onSubmit { history.setRemote(remote) }
                    .accessibilityLabel("Back up to")
                HStack {
                    Text("Slate keeps versions of your notes. With a git address it also sends them there.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if history.isSnapshotting {
                        ProgressView().controlSize(.small)
                    }
                    Button("Back up now") {
                        history.setRemote(remote)
                        Task { await history.backUpNow() }
                    }
                    .disabled(history.isSnapshotting || remote.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ClearHistoryRow()
                Picker("Keep notes in the Trash for", selection: $settings.trashRetentionDays) {
                    ForEach(SettingsStore.retentionChoices, id: \.self) { days in
                        Text("\(days) days").tag(days)
                    }
                }
            }
            AgentAccessSection()
            Section("Check-up") {
                ForEach(settings.checks) { check in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Image(systemName: check.isOK ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(check.isOK ? Tint.green.color : Tint.orange.color)
                            .accessibilityLabel(check.isOK ? "OK" : "Problem")
                        Text(check.title)
                        Spacer()
                        Text(check.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.trailing)
                            .textSelection(.enabled)
                    }
                }
                HStack {
                    Button("Check again") { Task { await settings.runDoctor() } }
                        .disabled(settings.isChecking)
                    Button("Activity") { showsActivity.toggle() }
                        .popover(isPresented: $showsActivity, arrowEdge: .bottom) {
                            ActivityView()
                        }
                    Spacer()
                    if settings.isRebuilding {
                        ProgressView().controlSize(.small)
                    }
                    Button("Rebuild search") { Task { await settings.rebuildIndex() } }
                        .disabled(settings.isRebuilding)
                        .help("Reads every note again. Your notes do not change.")
                }
            }
        }
        .formStyle(.grouped)
        .onAppear { remote = history.settings.remote }
        .onDisappear { history.setRemote(remote) }
        .task {
            await settings.refreshLoginStatus()
            await settings.runDoctor()
        }
    }
}

#Preview {
    GeneralSettingsView()
        .previewEnvironment()
        .frame(width: 480, height: 520)
}
