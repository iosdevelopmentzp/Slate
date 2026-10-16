import SwiftUI
import SlateDomain
import SlateUI

struct NoteListView: View {
    @Environment(NoteListStore.self) private var store
    @Environment(VaultStore.self) private var vault
    @Environment(Navigator.self) private var navigator

    var body: some View {
        if store.source == .trash {
            TrashListView()
        } else {
            notes
        }
    }

    private var notes: some View {
        let notes = store.visibleNotes
        let now = Date.now
        return ListState(
            failure: store.failure.map { .failure("Cannot read the notes", description: $0) { refresh() } },
            isLoading: store.isLoading && notes.isEmpty,
            loadingTitle: "Reading notes…",
            empty: emptyMessage(isEmpty: notes.isEmpty),
            noResultsFor: notes.isEmpty && store.filterText.isEmpty == false ? store.filterText : nil
        ) {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(notes) { summary in
                        NoteRow(
                            model: NoteRowMapper.model(for: summary, type: vault.type(named: summary.type), now: now),
                            isSelected: summary.id == navigator.selectedNote,
                            isConfirmingTrash: store.confirmingTrash == summary.id,
                            actions: actions(for: summary),
                            onCancelTrash: { store.cancelTrash() },
                            onConfirmTrash: { Task { await store.confirmTrash(summary) } }
                        )
                        .onTapGesture { store.select(summary.id) }
                    }
                }
                .padding(8)
            }
        }
        .background(Theme.surface)
    }

    private func actions(for summary: NoteSummary) -> NoteRowActions {
        NoteRowActions(
            moveTargets: vault.spaces.filter { $0.folder != summary.space },
            canArchive: summary.space != vault.config.archiveSpace,
            pin: { Task { await store.togglePin(summary) } },
            move: { space in Task { await store.moveNote(summary, to: space) } },
            duplicate: { Task { await store.duplicateNote(summary) } },
            archive: { Task { await store.archiveNote(summary) } },
            requestTrash: { store.requestTrash(summary.id) }
        )
    }

    private func emptyMessage(isEmpty: Bool) -> ListMessage? {
        guard isEmpty, store.filterText.isEmpty, store.isLoading == false else { return nil }
        return ListMessage("No notes here yet.", systemImage: "note.text", description: "Press ⌘N to make one.")
    }

    private func refresh() {
        Task { await store.refresh() }
    }
}

#Preview("Light") {
    NoteListView()
        .previewEnvironment()
        .frame(width: 300, height: 500)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    NoteListView()
        .previewEnvironment()
        .frame(width: 300, height: 500)
        .preferredColorScheme(.dark)
}
