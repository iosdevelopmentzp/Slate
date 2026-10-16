import SwiftUI
import SlateDomain
import SlateUI

struct NewNoteMenu: View {
    static let kinds = ["note", "task", "snippet", "meeting"]

    @Environment(NoteListStore.self) private var store
    @Environment(VaultStore.self) private var vault

    var body: some View {
        Menu {
            ForEach(Self.kinds, id: \.self) { kind in
                let type = vault.type(named: kind)
                Button(type?.title ?? kind.capitalized, systemImage: type?.icon ?? "doc") {
                    Task { await store.createNote(type: kind) }
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
