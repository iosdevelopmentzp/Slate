import SwiftUI
import SlateDomain
import SlateUI

struct SpacePicker: View {
    @Environment(NoteListStore.self) private var store

    var body: some View {
        Menu {
            Button("All notes") { store.show(space: nil) }
            Divider()
            ForEach(store.spaces) { space in
                Button {
                    store.show(space: space.folder)
                } label: {
                    Label(space.folder.rawValue, systemImage: space.icon ?? "folder")
                }
            }
        } label: {
            Label(store.spaceTitle, systemImage: "folder")
        }
        .menuStyle(.button)
        .fixedSize()
        .hint("Choose a folder")
        .accessibilityLabel("Folder")
    }
}
