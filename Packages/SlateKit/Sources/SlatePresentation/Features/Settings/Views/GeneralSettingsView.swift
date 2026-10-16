import SwiftUI
import SlateDomain
import SlateUI

struct GeneralSettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(VaultStore.self) private var vault

    var body: some View {
        @Bindable var settings = settings
        Form {
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
                Picker("Text size", selection: $settings.editorFontSize) {
                    ForEach(SettingsStore.fontSizes, id: \.self) { size in
                        Text("\(size) pt").tag(size)
                    }
                }
                Picker("Appearance", selection: $settings.appearance) {
                    ForEach(AppAppearance.allCases) { appearance in
                        Text(appearance.title).tag(appearance)
                    }
                }
                Picker("Keep notes in the Trash for", selection: $settings.trashRetentionDays) {
                    ForEach(SettingsStore.retentionChoices, id: \.self) { days in
                        Text("\(days) days").tag(days)
                    }
                }
            }
            Section("Daily notes") {
                Toggle("Make a daily note for each day", isOn: $settings.daily.isEnabled)
                Toggle("Carry open checkboxes to the new day", isOn: $settings.daily.carriesOver)
                    .disabled(settings.daily.isEnabled == false)
                Picker("Template", selection: $settings.daily.template) {
                    ForEach(vault.templateNames, id: \.self) { name in
                        Text(vault.type(named: name)?.title ?? name.capitalized).tag(name)
                    }
                }
                .disabled(settings.daily.isEnabled == false)
            }
            Section("Doctor") {
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
