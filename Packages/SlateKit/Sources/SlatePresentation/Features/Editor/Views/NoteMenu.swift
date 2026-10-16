import SwiftUI
import SlateDomain
import SlateUI

struct NoteMenu: View {
    @Environment(EditorStore.self) private var editor
    @Environment(VaultStore.self) private var vault
    @Environment(\.openNoteWindow) private var openNoteWindow
    @Environment(\.surface) private var surface
    let document: NoteDocument

    var body: some View {
        OverflowMenu {
            let actions = vault.actions.filter { $0.applies(to: document) }
            if actions.isEmpty == false {
                Section("Actions") {
                    ForEach(actions) { action in
                        Button(action.title, systemImage: action.icon ?? "play") {
                            Task { await editor.run(action) }
                        }
                    }
                }
            }
            if surface != .floating {
                Section {
                    Button("Float on Top", systemImage: "pin.circle") { openNoteWindow(document.id, true) }
                    Button("Open in New Window", systemImage: "macwindow.badge.plus") { openNoteWindow(document.id, false) }
                }
            }
            Section("Share") {
                Button("Copy as Markdown", systemImage: "doc.on.doc") { editor.copyMarkdown() }
                Button("Copy for Slack", systemImage: "bubble.left") { editor.copySlack() }
                Button("Save as HTML", systemImage: "globe") { Task { await editor.saveHTML() } }
                Button("Save as PDF", systemImage: "doc.richtext") { Task { await editor.savePDF() } }
            }
        }
        .hint("More for this note")
        .accessibilityLabel("More for this note")
    }
}

#Preview {
    NoteMenu(document: NoteDocument(path: VaultPath(rawValue: "Tasks/A.md"), header: NoteHeader(), body: "", hash: ContentHash(rawValue: ""), meta: FileMeta(path: VaultPath(rawValue: "Tasks/A.md"), created: .now, modified: .now, size: 0)))
        .previewEnvironment()
        .padding()
}
