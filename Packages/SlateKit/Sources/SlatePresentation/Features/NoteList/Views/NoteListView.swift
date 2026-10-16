import SwiftUI
import SlateDomain
import SlateUI

struct NoteListView: View {
    @Environment(NoteListStore.self) private var store
    @Environment(VaultStore.self) private var vault
    @Environment(Navigator.self) private var navigator
    @Environment(SearchStore.self) private var search

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
        let now = Date.now
        if let failure = store.failure, notes.isEmpty {
            EmptyStateView(systemImage: "exclamationmark.triangle", title: "Slate cannot read the notes. \(failure)", actionTitle: "Try again") {
                Task { await store.refresh() }
            }
        } else if notes.isEmpty, store.isLoading == false {
            EmptyStateView(systemImage: "square.and.pencil", title: "Nothing here yet.", actionTitle: "New note", shortcut: "⌘N") {
                Task { await store.createNote() }
            }
        } else {
            ScrollView {
                LazyVStack(spacing: Theme.cardGap) {
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

    private func actions(for summary: NoteSummary) -> NoteRowActions {
        NoteRowActions(
            moveTargets: vault.spaces.filter { $0.folder != summary.space },
            pin: { Task { await store.togglePin(summary) } },
            move: { space in Task { await store.moveNote(summary, to: space) } },
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
