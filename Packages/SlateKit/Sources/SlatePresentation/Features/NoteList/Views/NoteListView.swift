import SwiftUI
import SlateDomain
import SlateUI

struct NoteListView: View {
    @Environment(NoteListStore.self) private var store
    @Environment(VaultStore.self) private var vault
    @Environment(Navigator.self) private var navigator
    @Environment(SearchStore.self) private var search

    @State private var dropTarget: FolderPath?

    var body: some View {
        if store.source == .trash {
            TrashListView()
        } else if search.isActive {
            SearchResultsView()
        } else {
            notes
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
        } else if notes.isEmpty, folders.isEmpty, store.isLoading == false {
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

    private var subfolders: [FolderRowModel] {
        guard let folder = store.source.folder else { return [] }
        let space = vault.spaces.first { $0.folder == folder.space }
        return vault.children(of: folder).map { child in
            FolderRowMapper.model(forSubfolder: child, space: space, count: store.count(in: child))
        }
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
            moveTargets: NoteRowMapper.moveTargets(for: summary, spaces: vault.spaces, folders: vault.subfolders),
            pin: { Task { await store.togglePin(summary) } },
            move: { folder in Task { await store.moveNote(summary, toFolder: folder) } },
            duplicate: { Task { await store.duplicateNote(summary) } },
            requestTrash: { store.requestTrash(summary.id) }
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
