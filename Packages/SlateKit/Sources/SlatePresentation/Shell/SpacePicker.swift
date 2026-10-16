import SwiftUI
import SlateDomain
import SlateUI

struct SpacePicker: View {
    @Environment(NoteListStore.self) private var store
    @Environment(VaultStore.self) private var vault
    @Environment(SearchStore.self) private var search

    var body: some View {
        @Bindable var store = store
        Menu {
            Button("All notes", systemImage: "tray.full") { store.show(.all) }
            Divider()
            ForEach(vault.spaces) { space in
                Button(space.folder.rawValue, systemImage: space.icon ?? "folder") {
                    store.show(.space(space.folder))
                }
            }
            Divider()
            Button("Open TODOs", systemImage: "checklist") { store.show(.todos) }
            if vault.views.isEmpty == false {
                Menu("Saved searches", systemImage: "magnifyingglass") {
                    ForEach(vault.views) { view in
                        Button(view.title, systemImage: view.icon) { search.showSaved(view) }
                    }
                }
            }
            Button("Trash", systemImage: "trash") { store.show(.trash) }
            Divider()
            Picker("Sort by", selection: $store.sort) {
                Text("Date changed").tag(NoteSort.updated)
                Text("Date created").tag(NoteSort.created)
                Text("Title").tag(NoteSort.title)
            }
        } label: {
            Label(title, systemImage: icon)
        }
        .menuStyle(.button)
        .fixedSize()
        .hint("Choose a folder")
        .accessibilityLabel("Folder")
    }

    private var title: String {
        switch store.source {
        case .all: "All notes"
        case .trash: "Trash"
        case .todos: "Open TODOs"
        case .space(let name): name.rawValue
        }
    }

    private var icon: String {
        switch store.source {
        case .all: "tray.full"
        case .trash: "trash"
        case .todos: "checklist"
        case .space(let name): vault.spaces.first { $0.folder == name }?.icon ?? "folder"
        }
    }
}
