import SwiftUI
import SlateDomain
import SlateUI

struct SearchResultsView: View {
    @Environment(SearchStore.self) private var search
    @Environment(VaultStore.self) private var vault
    @Environment(Navigator.self) private var navigator

    var body: some View {
        let results = search.results
        let now = Date.now
        VStack(spacing: 0) {
            if let scope = search.scopeName {
                HStack(spacing: 6) {
                    Text("In \(scope)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Search all notes") { search.searchAllNotes() }
                        .buttonStyle(.link)
                        .font(.caption)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            ListState(
                failure: nil,
                isLoading: search.isSearching && results.isEmpty,
                loadingTitle: "Searching…",
                empty: nil,
                noResultsFor: results.isEmpty && search.isSearching == false ? search.query : nil
            ) {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(results) { hit in
                            SearchResultRow(
                                model: SearchResultMapper.model(for: hit, words: search.words, type: vault.type(named: hit.summary.type), now: now),
                                isSelected: hit.id == navigator.selectedNote
                            )
                            .onTapGesture { search.open(hit) }
                        }
                    }
                    .padding(8)
                }
            }
        }
        .background(Theme.surface)
    }
}

#Preview("Light") {
    SearchResultsView()
        .previewEnvironment()
        .frame(width: 300, height: 500)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    SearchResultsView()
        .previewEnvironment()
        .frame(width: 300, height: 500)
        .preferredColorScheme(.dark)
}
