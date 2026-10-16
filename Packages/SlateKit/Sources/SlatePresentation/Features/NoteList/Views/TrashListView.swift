import SwiftUI
import SlateDomain
import SlateUI

struct TrashListView: View {
    @Environment(NoteListStore.self) private var store

    var body: some View {
        let items = store.visibleTrash
        ListState(
            failure: nil,
            isLoading: false,
            loadingTitle: "",
            empty: items.isEmpty && store.filterText.isEmpty ? ListMessage("The Trash is empty.", systemImage: "trash", description: "") : nil,
            noResultsFor: items.isEmpty && store.filterText.isEmpty == false ? store.filterText : nil
        ) {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(items) { item in
                        TrashRow(model: TrashRowMapper.model(for: item, now: .now)) {
                            Task { await store.restoreItem(item) }
                        }
                    }
                }
                .padding(8)
            }
        }
        .background(Theme.surface)
    }
}

#Preview("Light") {
    TrashListView()
        .previewEnvironment()
        .frame(width: 300, height: 400)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    TrashListView()
        .previewEnvironment()
        .frame(width: 300, height: 400)
        .preferredColorScheme(.dark)
}
