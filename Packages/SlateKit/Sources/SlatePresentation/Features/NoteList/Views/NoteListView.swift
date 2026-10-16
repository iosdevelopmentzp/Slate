import SwiftUI
import SlateDomain
import SlateUI

struct NoteListView: View {
    @Environment(NoteListStore.self) private var store
    @Environment(VaultStore.self) private var vault
    @Environment(Navigator.self) private var navigator
    @Environment(SearchStore.self) private var search
    @State private var showsDone = false

    var body: some View {
        if store.source == .trash {
            TrashListView()
        } else if store.source == .todos {
            TodoListView()
        } else if search.isActive {
            SearchResultsView()
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
                    if groupsTasks {
                        ForEach(TaskGroupPolicy.grouped(notes), id: \.group) { group in
                            groupHeader(group.group, count: group.notes.count)
                            if group.group != .done || showsDone {
                                ForEach(group.notes) { summary in
                                    row(summary, now: now)
                                }
                            }
                        }
                    } else {
                        ForEach(notes) { summary in
                            row(summary, now: now)
                        }
                    }
                }
                .padding(8)
            }
        }
        .background(Theme.surface)
    }

    private var groupsTasks: Bool {
        guard let space = store.source.space else { return false }
        return vault.config.space(space)?.defaultType == NoteType.task.name
    }

    private func row(_ summary: NoteSummary, now: Date) -> some View {
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

    private func groupHeader(_ group: TaskGroupPolicy.Group, count: Int) -> some View {
        ListSectionHeader(TaskGroupText.title(group).uppercased(), detail: group == .done ? "\(count)" : nil) {
            if group == .done {
                Button {
                    showsDone.toggle()
                } label: {
                    Image(systemName: showsDone ? "chevron.down" : "chevron.right")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .accessibilityLabel(showsDone ? "Hide done tasks" : "Show done tasks")
            }
        }
        .padding(.horizontal, 12)
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
