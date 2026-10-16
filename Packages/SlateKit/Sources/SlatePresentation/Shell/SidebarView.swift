import SwiftUI
import SlateDomain
import SlateUI

struct SidebarView: View {
    @Environment(NoteListStore.self) private var store
    @Environment(VaultStore.self) private var vault

    @State private var editing: SpaceName?
    @State private var isCreating = false
    @State private var draft = ""
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Folders")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    IconButton(systemImage: "plus", help: "New folder") {
                        draft = ""
                        editing = nil
                        isCreating = true
                        isFieldFocused = true
                    }
                    .accessibilityLabel("New folder")
                }
                .padding(.leading, 8)
                .padding(.bottom, 2)
                row("All notes", systemImage: "tray.full", source: .all, count: store.count(in: nil))
                ForEach(vault.spaces) { space in
                    if editing == space.folder {
                        nameField { name in await vault.rename(space.folder, to: name) }
                    } else {
                        row(space.folder.rawValue, systemImage: space.icon ?? "folder", source: .space(space.folder), count: store.count(in: space.folder))
                            .contextMenu { menu(for: space) }
                    }
                }
                if isCreating {
                    nameField { name in await vault.create(named: name) }
                }
                Divider()
                    .padding(.vertical, 6)
                row("Trash", systemImage: "trash", source: .trash, count: nil)
            }
            .padding(8)
        }
        .frame(maxHeight: .infinity)
        .background(Theme.base)
    }

    @ViewBuilder
    private func menu(for space: Space) -> some View {
        Button("Rename", systemImage: "pencil") {
            draft = space.folder.rawValue
            isCreating = false
            editing = space.folder
            isFieldFocused = true
        }
        Menu("Icon", systemImage: space.icon ?? "folder") {
            ForEach(VaultStore.icons, id: \.self) { icon in
                Button(icon, systemImage: icon) {
                    Task { await vault.setIcon(icon, for: space.folder) }
                }
                .labelStyle(.iconOnly)
            }
        }
        Divider()
        Button("Move up", systemImage: "arrow.up") {
            Task { await vault.move(space.folder, by: -1) }
        }
        .disabled(vault.canMove(space.folder, by: -1) == false)
        Button("Move down", systemImage: "arrow.down") {
            Task { await vault.move(space.folder, by: 1) }
        }
        .disabled(vault.canMove(space.folder, by: 1) == false)
    }

    private func nameField(commit: @escaping (String) async -> Bool) -> some View {
        TextField("Folder name", text: $draft)
            .textFieldStyle(.roundedBorder)
            .focused($isFieldFocused)
            .onSubmit {
                let name = draft
                Task {
                    if await commit(name) {
                        endEditing()
                    }
                }
            }
            .onExitCommand(perform: endEditing)
            .onChange(of: isFieldFocused) { _, focused in
                if focused == false { endEditing() }
            }
            .padding(.horizontal, 4)
    }

    private func endEditing() {
        editing = nil
        isCreating = false
        draft = ""
    }

    private func row(_ title: String, systemImage: String, source: ListSource, count: Int?) -> some View {
        let isSelected = store.source == source
        return HStack(spacing: 8) {
            Label(title, systemImage: systemImage)
                .lineLimit(1)
            Spacer(minLength: 4)
            if let count {
                Text("\(count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isSelected ? Theme.selection.opacity(0.18) : .clear, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture { store.show(source) }
    }
}

#Preview("Light") {
    SidebarView()
        .previewEnvironment(surface: .window)
        .frame(width: 200, height: 400)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    SidebarView()
        .previewEnvironment(surface: .window)
        .frame(width: 200, height: 400)
        .preferredColorScheme(.dark)
}
