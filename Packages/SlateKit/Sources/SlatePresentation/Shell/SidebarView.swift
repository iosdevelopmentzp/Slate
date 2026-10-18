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

    @State private var dropTarget: FolderPath?
    @State private var isProjectDropTarget = false

    var body: some View {
        @Bindable var vault = vault
        VStack(spacing: 0) {
            topBar
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    sourceRow(.all, title: "All notes", icon: "tray.full", count: store.count(in: nil))
                    ForEach(rows(for: vault.folderSpaces)) { row in
                        folder(row)
                        if row.id == fieldAfter, case .newInside(let parent) = vault.editing {
                            FolderNameField(
                                name: $vault.draftName,
                                icon: "folder",
                                tint: Tint.blue.color,
                                onCommit: { Task { await vault.commitEdit() } },
                                onCancel: { vault.cancelEdit() }
                            )
                            .padding(.leading, CGFloat(parent.depth) * 14 + 18)
                        }
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
                    projectsSection
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

    @ViewBuilder
    private var projectsSection: some View {
        @Bindable var vault = vault
        HStack(spacing: 4) {
            Text("Projects")
                .font(.callout.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Menu {
                Button("New Project", systemImage: SetProjectUseCase.projectIcon) { vault.startNewProject() }
                Button("Import Folder…", systemImage: "square.and.arrow.down") { importFolder() }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .menuIndicator(.hidden)
            .fixedSize()
            .foregroundStyle(.secondary)
            .hint("New project or import a folder")
            .accessibilityLabel("New project")
        }
        .padding(.leading, 8)
        .padding(.top, 12)
        .padding(.vertical, 2)
        .background(isProjectDropTarget ? Theme.selection.opacity(0.18) : .clear, in: RoundedRectangle(cornerRadius: Theme.pillRadius, style: .continuous))
        .dropDestination(for: URL.self) { urls, _ in
            let folders = urls.filter { $0.hasDirectoryPath }
            guard folders.isEmpty == false else { return false }
            Task {
                for folder in folders {
                    await vault.importProject(from: folder)
                }
            }
            return true
        } isTargeted: { isProjectDropTarget = $0 }
        ForEach(rows(for: vault.projects)) { row in
            folder(row)
            if row.id == fieldAfter, case .newInside(let parent) = vault.editing {
                FolderNameField(
                    name: $vault.draftName,
                    icon: "folder",
                    tint: Tint.blue.color,
                    onCommit: { Task { await vault.commitEdit() } },
                    onCancel: { vault.cancelEdit() }
                )
                .padding(.leading, CGFloat(parent.depth) * 14 + 18)
            }
            if row.id == fieldAfter, case .newTask(let project) = vault.editing {
                FolderNameField(
                    name: $vault.draftName,
                    icon: "checkmark.circle",
                    tint: Tint.blue.color,
                    prompt: "ABC-123 Task title",
                    onCommit: { Task { await vault.commitEdit() } },
                    onCancel: { vault.cancelEdit() }
                )
                .padding(.leading, CGFloat(FolderPath(space: project).depth) * 14 + 18)
            }
        }
        if vault.editing == .newProject {
            FolderNameField(
                name: $vault.draftName,
                icon: SetProjectUseCase.projectIcon,
                tint: Tint.blue.color,
                onCommit: { Task { await vault.commitEdit() } },
                onCancel: { vault.cancelEdit() }
            )
        } else if vault.projects.isEmpty {
            Text("A project keeps the notes, tasks and files of one code repository.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var rows: [SidebarFolder] {
        rows(for: vault.folderSpaces) + rows(for: vault.projects)
    }

    private func rows(for spaces: [Space]) -> [SidebarFolder] {
        spaces.flatMap { space -> [SidebarFolder] in
            let root = FolderPath(space: space.folder)
            let model = FolderRowMapper.model(for: space, count: store.count(in: root), defaultFolder: vault.defaultFolder)
            let head = SidebarFolder(model: model, level: 0, disclosure: disclosure(hasChildren: vault.children(of: root).isEmpty == false, isExpanded: vault.isExpanded(root)))
            guard vault.isExpanded(root) else { return [head] }
            let below = vault.tree.nodes(below: space.folder, expanded: vault.expanded).map { node in
                SidebarFolder(
                    model: FolderRowMapper.model(forSubfolder: node.id, space: space, count: store.count(in: node.id)),
                    level: node.level,
                    disclosure: disclosure(hasChildren: node.hasChildren, isExpanded: node.isExpanded)
                )
            }
            return [head] + below
        }
    }

    private var fieldAfter: FolderPath? {
        let parent: FolderPath
        switch vault.editing {
        case .newInside(let folder): parent = folder
        case .newTask(let project): parent = FolderPath(space: project)
        default: return nil
        }
        return rows.last { $0.id == parent || parent.contains($0.id) }?.id
    }

    private func disclosure(hasChildren: Bool, isExpanded: Bool) -> FolderRow.Disclosure {
        guard hasChildren else { return .empty }
        return isExpanded ? .expanded : .collapsed
    }

    private func isRenaming(_ model: FolderRowModel) -> Bool {
        model.isSpace ? vault.editing == .rename(model.space) : vault.editing == .renameFolder(model.id)
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
    private func folder(_ row: SidebarFolder) -> some View {
        let model = row.model
        if isRenaming(model) {
            @Bindable var vault = vault
            FolderNameField(
                name: $vault.draftName,
                icon: model.icon,
                tint: model.tint.color,
                onCommit: { Task { await vault.commitEdit() } },
                onCancel: { vault.cancelEdit() }
            )
            .padding(.leading, CGFloat(row.level) * 14 + 18)
        } else {
            VStack(spacing: 4) {
                FolderRow(
                    title: model.title,
                    icon: model.icon,
                    tint: model.tint.color,
                    count: model.count,
                    isSelected: store.source == .showing(model.id),
                    isDropTarget: dropTarget == model.id,
                    level: row.level,
                    disclosure: row.disclosure,
                    onToggle: { vault.setExpanded(model.id, vault.isExpanded(model.id) == false) }
                )
                .onTapGesture { show(.showing(model.id)) }
                .simultaneousGesture(TapGesture(count: 2).onEnded { vault.startRename(folder: model.id) })
                .contextMenu { menu(for: model) }
                .dropDestination(for: String.self) { items, _ in
                    drop(items, on: model.id)
                } isTargeted: { isTargeted in
                    dropTarget = isTargeted ? model.id : (dropTarget == model.id ? nil : dropTarget)
                }
                if vault.confirmingDelete == model.id {
                    FolderDeleteConfirmation(
                        question: model.deleteQuestion,
                        onConfirm: { Task { await vault.confirmDelete(folder: model.id) } },
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
            canMoveUp: vault.canMove(model.space, by: -1),
            canMoveDown: vault.canMove(model.space, by: 1),
            onNewInside: { vault.startNewFolder(in: model.id) },
            onRename: { vault.startRename(folder: model.id) },
            onColor: { color in Task { await vault.setColor(color, for: model.space) } },
            onIcon: { icon in Task { await vault.setIcon(icon, for: model.space) } },
            onMove: { offset in Task { await vault.move(model.space, by: offset) } },
            onProject: { isProject in Task { await vault.setProject(isProject, for: model.space) } },
            onNewTask: { vault.startNewTask(in: model.space) },
            onLinkRepository: { linkRepository(for: model.space) },
            onDelete: { vault.requestDelete(folder: model.id) }
        )
    }

    private func importFolder() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        guard let folder = FolderPicker.chooseFolder(directory: home, prompt: "Import", message: "Choose a folder to copy into Slate as a project. The folder itself does not change.") else { return }
        Task { await vault.importProject(from: folder) }
    }

    private func linkRepository(for space: SpaceName) {
        let home = FileManager.default.homeDirectoryForCurrentUser
        guard let folder = FolderPicker.chooseFolder(directory: home, prompt: "Link", message: "Choose the code repository of \(space.rawValue).") else { return }
        Task { await vault.linkRepository(folder, to: space) }
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

    private func drop(_ items: [String], on folder: FolderPath) -> Bool {
        let ids = items.compactMap(NoteDragPayload.noteID(from:))
        guard ids.isEmpty == false else { return false }
        Task {
            for id in ids {
                await store.moveNote(id: id, toFolder: folder)
            }
        }
        return true
    }
}

private struct SidebarFolder: Identifiable {
    let model: FolderRowModel
    let level: Int
    let disclosure: FolderRow.Disclosure

    var id: FolderPath {
        model.id
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
