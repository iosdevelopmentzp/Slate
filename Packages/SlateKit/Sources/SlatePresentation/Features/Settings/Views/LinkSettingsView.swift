import SwiftUI
import SlateDomain
import SlateUI

struct LinkSettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(IssueStore.self) private var issues
    @State private var token = ""
    @State private var testResult: String?

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section {
                TextField("Ticket tracker address", text: $settings.tracker.trackerBaseURL, prompt: Text("https://example.atlassian.net"))
                TextField("Ticket key pattern", text: $settings.tracker.ticketPattern)
                    .font(.body.monospaced())
                TextField("Name for a ticket", text: $settings.tracker.ticketLabel)
            } header: {
                Text("Tickets")
            } footer: {
                Text("A ticket key like ABC-123 in a note opens the ticket in the tracker.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section {
                TextField("Email for the tracker", text: $settings.tracker.trackerEmail, prompt: Text("me@example.com"))
                SecureField(issues.hasToken ? "A token is saved" : "API token", text: $token)
                HStack {
                    if let testResult {
                        Text(testResult)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    Spacer()
                    Button("Save token") {
                        Task {
                            try? await issues.saveToken(token)
                            token = ""
                        }
                    }
                    .disabled(token.isEmpty)
                    Button("Test") {
                        Task {
                            await settings.saveTracker()
                            testResult = await issues.test()
                        }
                    }
                }
            } header: {
                Text("Ticket details")
            } footer: {
                Text("With a token, a task shows the title, status and person of its ticket. The token stays in the Keychain. Leave it empty to turn this off.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section {
                TextField("Git host address", text: $settings.tracker.gitHostBaseURL, prompt: Text("https://gitlab.example.com"))
                TextField("Project path", text: $settings.tracker.gitProjectPath, prompt: Text("group/project"))
                TextField("Name for a merge request", text: $settings.tracker.mergeRequestLabel)
            } header: {
                Text("Merge requests")
            } footer: {
                Text("!1234 opens a merge request and #12 an issue of this project.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section {
                HStack {
                    if settings.trackerSaved {
                        Label("Saved to .slate/links.json", systemImage: "checkmark")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Save") { Task { await settings.saveTracker() } }
                        .keyboardShortcut(.defaultAction)
                }
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    LinkSettingsView()
        .previewEnvironment()
        .frame(width: 480, height: 480)
}
