import SwiftUI
import SlateDomain
import SlateUI

struct NoteListView: View {
    @Environment(NoteListStore.self) private var store
    @Environment(Navigator.self) private var navigator

    var body: some View {
        let notes = store.visibleNotes
        ListState(
            failure: store.failure.map { .failure("Cannot read the notes", description: $0) { refresh() } },
            isLoading: store.isLoading,
            loadingTitle: "Reading notes…",
            empty: emptyMessage(isEmpty: notes.isEmpty),
            noResultsFor: notes.isEmpty && store.filterText.isEmpty == false ? store.filterText : nil
        ) {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(notes) { summary in
                        NoteRow(
                            model: NoteRowMapper.model(for: summary, now: .now),
                            isSelected: summary.id == navigator.selectedNote
                        )
                        .onTapGesture { store.select(summary.id) }
                    }
                }
                .padding(8)
            }
        }
        .background(Theme.surface)
    }

    private func emptyMessage(isEmpty: Bool) -> ListMessage? {
        guard isEmpty, store.filterText.isEmpty else { return nil }
        return ListMessage("No notes here yet.", systemImage: "note.text", description: "")
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
