import SwiftUI
import SlateDomain
import SlateUI

struct SearchResultsView: View {
    @Environment(SearchStore.self) private var search
    @Environment(Navigator.self) private var navigator

    var body: some View {
        let results = search.results
        let now = Date.now
        VStack(spacing: 0) {
            if let scope = search.scopeName {
                HStack(spacing: 6) {
                    Text("In \(scope)")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Search all notes") { search.searchAllNotes() }
                        .buttonStyle(.link)
                        .font(.callout)
                }
                .padding(.horizontal, Theme.columnPadding + 4)
                .padding(.bottom, 6)
            }
            if results.isEmpty, search.isSearching == false {
                VStack(spacing: 8) {
                    Text("No notes match.")
                        .foregroundStyle(.secondary)
                    Button("Clear search") { search.clear() }
                        .buttonStyle(.link)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: Theme.cardGap) {
                        ForEach(results) { hit in
                            SearchResultRow(
                                model: SearchResultMapper.model(for: hit, words: search.words, now: now),
                                isSelected: hit.id == navigator.selectedNote
                            )
                            .onTapGesture { search.open(hit) }
                        }
                    }
                    .padding(.horizontal, Theme.columnPadding)
                    .padding(.bottom, Theme.columnPadding)
                }
            }
        }
    }
}

#Preview("Light") {
    SearchResultsView()
        .previewEnvironment()
        .frame(width: 320, height: 500)
        .background(Theme.base)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    SearchResultsView()
        .previewEnvironment()
        .frame(width: 320, height: 500)
        .background(Theme.base)
        .preferredColorScheme(.dark)
}
