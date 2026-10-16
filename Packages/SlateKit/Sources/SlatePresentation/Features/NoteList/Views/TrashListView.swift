import SwiftUI
import SlateDomain
import SlateUI

struct TrashListView: View {
    @Environment(NoteListStore.self) private var store
    @Environment(SettingsStore.self) private var settings

    var body: some View {
        let items = store.visibleTrash
        VStack(spacing: 0) {
            if items.isEmpty, store.filterText.isEmpty {
                EmptyStateView(systemImage: "trash", title: "The Trash is empty.")
            } else if items.isEmpty {
                VStack(spacing: 8) {
                    Text("No notes match.")
                        .foregroundStyle(.secondary)
                    Button("Clear search") { store.filterText = "" }
                        .buttonStyle(.link)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: Theme.cardGap) {
                        ForEach(items) { item in
                            TrashRow(
                                model: TrashRowMapper.model(for: item, now: .now),
                                onRestore: { Task { await store.restoreItem(item) } },
                                onDelete: { Task { await store.deleteNow(item) } }
                            )
                        }
                    }
                    .padding(.horizontal, Theme.columnPadding)
                    .padding(.bottom, Theme.columnPadding)
                }
            }
            Text("Notes are removed from the Trash after \(settings.trashRetentionDays) days.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
    }
}

#Preview("Light") {
    TrashListView()
        .previewEnvironment()
        .frame(width: 320, height: 400)
        .background(Theme.base)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    TrashListView()
        .previewEnvironment()
        .frame(width: 320, height: 400)
        .background(Theme.base)
        .preferredColorScheme(.dark)
}
