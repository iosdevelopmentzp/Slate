import SwiftUI
import SlateDomain
import SlateUI

struct SidebarView: View {
    @Environment(NoteListStore.self) private var store
    @Environment(VaultStore.self) private var vault
    @Environment(SearchStore.self) private var search
    @Environment(\.surface) private var surface
    @Environment(\.openAsWindow) private var openAsWindow
    @Environment(\.openSettings) private var openSettings

    @State private var dropTarget: SpaceName?

    var body: some View {
        @Bindable var vault = vault
        VStack(spacing: 0) {
            topBar
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    sourceRow(.all, title: "All notes", icon: "tray.full", count: store.count(in: nil))
                    ForEach(models) { model in
                        folder(model)
                    }
                    if vault.editing == .new {
                        FolderNameField(
                            name: $vault.draftName,
                            icon: "folder.fill",
                            tint: Tint.blue.color,
                            onCommit: { Task { await vault.commitEdit() } },
                            onCancel: { vault.cancelEdit() }
                        )
                    }
                    sourceRow(.trash, title: "Trash", icon: "trash", count: nil)
                        .padding(.top, 10)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
            newFolderButton
        }
        .frame(maxHeight: .infinity)
        .background(Theme.base)
    }

    private var models: [FolderRowModel] {
        vault.spaces.map { space in
            FolderRowMapper.model(for: space, count: store.count(in: space.folder), defaultFolder: vault.defaultFolder)
        }
    }

    private var topBar: some View {
        HStack(spacing: 4) {
            Text("Folders")
                .font(.callout.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            if surface == .panel {
                IconButton(systemImage: "macwindow", help: "Open as window (⌘⇧O)") { openAsWindow() }
                    .accessibilityLabel("Open as window")
            }
            IconButton(systemImage: "gearshape", help: "Settings (⌘,)") { openSettings() }
                .accessibilityLabel("Settings")
        }
        .padding(.leading, surface == .window ? WindowLayout.trafficLightsWidth : 16)
        .padding(.trailing, 10)
        .frame(height: 44)
        .background(PanelDragArea())
    }

    @ViewBuilder
    private func folder(_ model: FolderRowModel) -> some View {
        if vault.editing == .rename(model.id) {
            @Bindable var vault = vault
            FolderNameField(
                name: $vault.draftName,
                icon: model.icon,
                tint: model.tint.color,
                onCommit: { Task { await vault.commitEdit() } },
                onCancel: { vault.cancelEdit() }
            )
        } else {
            VStack(spacing: 4) {
                FolderRow(
                    title: model.title,
                    icon: model.icon,
                    tint: model.tint.color,
                    count: model.count,
                    isSelected: store.source == .space(model.id),
                    isDropTarget: dropTarget == model.id
                )
                .onTapGesture { show(.space(model.id)) }
                .simultaneousGesture(TapGesture(count: 2).onEnded { vault.startRename(model.id) })
                .contextMenu { menu(for: model) }
                .dropDestination(for: String.self) { items, _ in
                    drop(items, on: model.id)
                } isTargeted: { isTargeted in
                    dropTarget = isTargeted ? model.id : (dropTarget == model.id ? nil : dropTarget)
                }
                if vault.confirmingDelete == model.id {
                    FolderDeleteConfirmation(
                        question: model.deleteQuestion,
                        onConfirm: { Task { await vault.confirmDelete(model.id) } },
                        onCancel: { vault.cancelDelete() }
                    )
                    .transition(.opacity)
                }
            }
            .animation(Theme.hoverAnimation, value: vault.confirmingDelete)
        }
    }

    private func menu(for model: FolderRowModel) -> some View {
        FolderMenu(
            model: model,
            canMoveUp: vault.canMove(model.id, by: -1),
            canMoveDown: vault.canMove(model.id, by: 1),
            onRename: { vault.startRename(model.id) },
            onColor: { color in Task { await vault.setColor(color, for: model.id) } },
            onIcon: { icon in Task { await vault.setIcon(icon, for: model.id) } },
            onMove: { offset in Task { await vault.move(model.id, by: offset) } },
            onDelete: { vault.requestDelete(model.id) }
        )
    }

    private func sourceRow(_ source: ListSource, title: String, icon: String, count: Int?) -> some View {
        FolderRow(title: title, icon: icon, tint: .secondary, count: count, isSelected: store.source == source, isDropTarget: false)
            .onTapGesture { show(source) }
    }

    private var newFolderButton: some View {
        Button {
            vault.startNewFolder()
        } label: {
            Label("New folder", systemImage: "plus")
                .font(.callout.weight(.medium))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .frame(height: 30)
                .background(Theme.hover, in: RoundedRectangle(cornerRadius: Theme.pillRadius, style: .continuous))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .padding(8)
        .hint("New folder (⇧⌘N)")
        .accessibilityLabel("New folder")
    }

    private func show(_ source: ListSource) {
        search.clear()
        store.show(source)
    }

    private func drop(_ items: [String], on space: SpaceName) -> Bool {
        let ids = items.compactMap(NoteDragPayload.noteID(from:))
        guard ids.isEmpty == false else { return false }
        Task {
            for id in ids {
                await store.moveNote(id: id, to: space)
            }
        }
        return true
    }
}

#Preview("Light") {
    SidebarView()
        .previewEnvironment(surface: .window)
        .frame(width: 200, height: 420)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    SidebarView()
        .previewEnvironment(surface: .window)
        .frame(width: 200, height: 420)
        .preferredColorScheme(.dark)
}
