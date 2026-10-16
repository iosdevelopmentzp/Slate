import SwiftUI
import SlateDomain
import SlateUI

struct NewNoteMenu: View {
    static let kinds = ["note", "task", "snippet", "meeting"]

    @Environment(NoteListStore.self) private var store
    @Environment(VaultStore.self) private var vault
    @Environment(DailyStore.self) private var daily
    @Environment(EditorStore.self) private var editor

    var body: some View {
        Menu {
            ForEach(Self.kinds, id: \.self) { kind in
                let type = vault.type(named: kind)
                Button(type?.title ?? kind.capitalized, systemImage: type?.icon ?? "doc") {
                    Task { await store.createNote(type: kind) }
                }
            }
            Divider()
            Button("Today", systemImage: "calendar") {
                Task { await daily.openToday() }
            }
            if editor.document != nil, vault.templateNames.isEmpty == false {
                Menu("Insert Template", systemImage: "doc.on.doc") {
                    ForEach(vault.templateNames, id: \.self) { name in
                        Button(vault.type(named: name)?.title ?? name.capitalized) {
                            Task { await editor.insertTemplate(named: name) }
                        }
                    }
                }
            }
        } label: {
            Label("New", systemImage: "plus")
        } primaryAction: {
            Task { await store.createNote() }
        }
        .menuStyle(.button)
        .fixedSize()
        .disabled(store.source == .trash)
        .hint("New note in this folder (⌘N). Open the menu for another kind.")
        .accessibilityLabel("New note")
    }
}
