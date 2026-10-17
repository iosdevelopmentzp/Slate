import SwiftUI
import SlateDomain
import SlateUI

struct AgentAccessSection: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(VaultStore.self) private var vault
    @Environment(\.copyToPasteboard) private var copyToPasteboard

    var body: some View {
        Section("AI access") {
            Text("Agents like Claude Code can read every note. Choose where they may change notes. Slate keeps a version before each change.")
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(vault.spaces) { space in
                Toggle(space.folder.rawValue, isOn: Binding(
                    get: { settings.agentPermissions.canWrite(in: FolderPath(space: space.folder)) },
                    set: { allowed in Task { await settings.setAgentAccess(space.folder, allowed: allowed) } }
                ))
            }
            Toggle("Allow agents to create notes", isOn: Binding(
                get: { settings.agentPermissions.allowCreate },
                set: { allowed in Task { await settings.setAgentsMayCreate(allowed) } }
            ))
            Toggle("Allow agents to move notes to the Trash", isOn: Binding(
                get: { settings.agentPermissions.allowTrash },
                set: { allowed in Task { await settings.setAgentsMayTrash(allowed) } }
            ))
            LabeledContent("Add to Claude Code") {
                HStack(spacing: 8) {
                    Text(AgentGuide.registration)
                        .font(.callout.monospaced())
                        .textSelection(.enabled)
                    Button("Copy") { copyToPasteboard(AgentGuide.registration, "Command") }
                }
            }
        }
        .task { await settings.loadAgentPermissions() }
    }
}

#Preview {
    Form {
        AgentAccessSection()
    }
    .formStyle(.grouped)
    .previewEnvironment()
    .frame(width: 480, height: 360)
}
