import SwiftUI
import SlateDomain
import SlateUI

struct NoteListView: View {
    @Environment(NoteListStore.self) private var store
    @Environment(VaultStore.self) private var vault
    @Environment(Navigator.self) private var navigator
    @Environment(SearchStore.self) private var search
    @Environment(FolderFilesStore.self) private var files

    @State private var dropTarget: FolderPath?
    @State private var isFileDropTarget = false
    @State private var versionsOf: VaultPath?

    var body: some View {
        if store.source == .trash {
            TrashListView()
        } else if search.isActive {
            SearchResultsView()
        } else {
            notes
                .dropDestination(for: URL.self) { urls, _ in
                    let local = urls.filter(\.isFileURL)
                    guard store.source.folder != nil, local.isEmpty == false else { return false }
                    Task { await files.importFiles(local) }
                    return true
                } isTargeted: { isFileDropTarget = $0 }
                .overlay {
                    if isFileDropTarget {
                        RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                            .strokeBorder(Theme.selection, lineWidth: 2)
                            .padding(4)
                            .allowsHitTesting(false)
                    }
                }
                .task(id: store.source) {
                    await files.show(store.source.folder)
                }
        }
    }

    @ViewBuilder
    private var notes: some View {
        let notes = store.visibleNotes
        let folders = subfolders
        let now = Date.now
        if let failure = store.failure, notes.isEmpty {
            EmptyStateView(systemImage: "exclamationmark.triangle", title: "Slate cannot read the notes. \(failure)", actionTitle: "Try again") {
                Task { await store.refresh() }
            }
        } else if notes.isEmpty, folders.isEmpty, files.files.isEmpty, store.isLoading == false {
            EmptyStateView(systemImage: "square.and.pencil", title: "Nothing here yet.", actionTitle: "New note", shortcut: "⌘N") {
                Task { await store.createNote() }
            }
        } else {
            ScrollView {
                LazyVStack(spacing: Theme.cardGap) {
                    ForEach(folders) { model in
                        subfolder(model)
                    }
                    ForEach(notes) { summary in
                        card(summary, now: now)
                    }
                    if files.files.isEmpty == false {
                        ListSectionHeader("Files", detail: "\(files.files.count)")
                        ForEach(files.files, id: \.path) { meta in
                            file(meta, now: now)
                        }
                    }
                }
                .padding(.horizontal, Theme.columnPadding)
                .padding(.bottom, Theme.columnPadding)
            }
        }
    }

    private func card(_ summary: NoteSummary, now: Date) -> some View {
        NoteCard(
            model: NoteRowMapper.model(for: summary, now: now),
            isSelected: summary.id == navigator.selectedNote,
            isConfirmingTrash: store.confirmingTrash == summary.id,
            actions: actions(for: summary),
            onCancelTrash: { store.cancelTrash() },
            onConfirmTrash: { Task { await store.confirmTrash(summary) } }
        )
        .onTapGesture { store.select(summary.id) }
    }

    @ViewBuilder
    private func file(_ meta: FileMeta, now: Date) -> some View {
        if files.renaming == meta.path {
            @Bindable var files = files
            FileNameField(
                name: $files.draftName,
                onCommit: { Task { await files.commitRename() } },
                onCancel: { files.cancelRename() }
            )
        } else {
            FileRow(model: FileRowMapper.model(for: meta, now: now), url: files.url(for: meta.path), actions: fileActions(for: meta.path))
                .popover(isPresented: Binding(get: { versionsOf == meta.path }, set: { if $0 == false { versionsOf = nil } }), arrowEdge: .trailing) {
                    FileVersionsView(path: meta.path)
                }
        }
    }

    private func fileActions(for path: VaultPath) -> FileRowActions {
        FileRowActions(
            quickLook: { Task { await files.quickLook(path) } },
            open: { Task { await files.open(path) } },
            reveal: { Task { await files.reveal(path) } },
            saveToDownloads: { Task { await files.saveToDownloads(path) } },
            copyPath: { files.copyPath(path) },
            rename: { files.startRename(path) },
            trash: { Task { await files.trash(path) } },
            versions: { versionsOf = path },
            drag: { files.dragProvider(for: path) }
        )
    }

    private var subfolders: [FolderRowModel] {
        guard let folder = store.source.folder else { return [] }
        let space = vault.spaces.first { $0.folder == folder.space }
        let children = vault.children(of: folder)
        guard space?.isProject == true, folder.isSpace else {
            return children.map { child in
                FolderRowMapper.model(forSubfolder: child, space: space, count: store.count(in: child))
            }
        }
        return children
            .map { child in
                FolderRowMapper.model(forTask: child, space: space, count: store.count(in: child), note: TaskStatusMapper.taskNote(in: child, among: store.summaries))
            }
            .sorted { $0.statusRank < $1.statusRank }
    }

    private func subfolder(_ model: FolderRowModel) -> some View {
        SubfolderCard(model: model, isDropTarget: dropTarget == model.id)
            .onTapGesture { store.show(.folder(model.id)) }
            .dropDestination(for: String.self) { items, _ in
                let ids = items.compactMap(NoteDragPayload.noteID(from:))
                guard ids.isEmpty == false else { return false }
                Task {
                    for id in ids {
                        await store.moveNote(id: id, toFolder: model.id)
                    }
                }
                return true
            } isTargeted: { isTargeted in
                dropTarget = isTargeted ? model.id : (dropTarget == model.id ? nil : dropTarget)
            }
    }

    private func actions(for summary: NoteSummary) -> NoteRowActions {
        NoteRowActions(
            moveTargets: NoteRowMapper.moveTargets(for: summary, among: vault.moveTargets),
            pin: { Task { await store.togglePin(summary) } },
            move: { folder in Task { await store.moveNote(summary, toFolder: folder) } },
            duplicate: { Task { await store.duplicateNote(summary) } },
            requestTrash: { store.requestTrash(summary.id) },
            copyPath: { store.copyPath(summary) },
            copyLink: { store.copyLink(summary) },
            drag: { store.dragProvider(for: summary) }
        )
    }
}

#Preview("Light") {
    NoteListView()
        .previewEnvironment()
        .frame(width: 320, height: 500)
        .background(Theme.base)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    NoteListView()
        .previewEnvironment()
        .frame(width: 320, height: 500)
        .background(Theme.base)
        .preferredColorScheme(.dark)
}
