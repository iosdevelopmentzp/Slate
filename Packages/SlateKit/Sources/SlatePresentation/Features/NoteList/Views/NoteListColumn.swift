import SwiftUI
import SlateDomain
import SlateUI

struct NoteListColumn: View {
    @Environment(NoteListStore.self) private var store
    @Environment(SearchStore.self) private var search
    @Environment(WindowLayout.self) private var layout
    @Environment(\.surface) private var surface
    @FocusState private var isSearchFocused: Bool
    @State private var showsChanges = false

    var body: some View {
        @Bindable var store = store
        @Bindable var search = search
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                if case .folder(let folder) = store.source, let parent = folder.parent {
                    IconButton(systemImage: "chevron.left", help: "Back to \(parent.name)") {
                        search.clear()
                        store.show(.showing(parent))
                    }
                    .accessibilityLabel("Back to \(parent.name)")
                }
                Text(title)
                    .font(.title2.weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 8)
                if let folder = store.source.folder {
                    IconButton(systemImage: "clock.arrow.circlepath", help: "Changes in this folder") {
                        showsChanges.toggle()
                    }
                    .popover(isPresented: $showsChanges, arrowEdge: .bottom) {
                        ChangesView(folder: folder) { path in
                            showsChanges = false
                            store.open(path)
                        }
                    }
                    .accessibilityLabel("Changes")
                }
                RoundButton(systemImage: "plus", help: "New note (⌘N)", isProminent: true) {
                    Task { await store.createNote() }
                }
                .disabled(store.source == .trash)
            }
            .padding(.leading, surface == .window && layout.showsSidebar == false ? WindowLayout.trafficLightsWidth : 16)
            .padding(.trailing, Theme.columnPadding)
            .frame(height: 44)
            .background(PanelDragArea())
            SearchField(prompt: store.source == .trash ? "Search the Trash" : "Search", text: store.source == .trash ? $store.filterText : $search.query, focus: $isSearchFocused)
                .onSubmit { search.openFirst() }
                .hint("Search notes (⌘F). Enter opens the first result, Esc clears.")
                .padding(.horizontal, Theme.columnPadding)
                .background(
                    Button("") { isSearchFocused = true }
                        .keyboardShortcut("f", modifiers: .command)
                        .opacity(0)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                )
            progressLine
            NoteListView()
        }
        .background(Theme.base)
    }

    private var title: String {
        switch store.source {
        case .all: "All notes"
        case .trash: "Trash"
        case .space(let name): name.rawValue
        case .folder(let folder): folder.name
        }
    }

    private var progressLine: some View {
        ZStack {
            if store.isLoading || search.isSearching {
                ProgressView()
                    .progressViewStyle(.linear)
                    .controlSize(.mini)
                    .padding(.horizontal, Theme.columnPadding + 4)
                    .transition(.opacity)
                    .accessibilityLabel("Reading notes")
            }
        }
        .frame(height: 8)
        .animation(Theme.hoverAnimation, value: store.isLoading || search.isSearching)
    }
}

#Preview("Light") {
    NoteListColumn()
        .previewEnvironment()
        .frame(width: 320, height: 520)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    NoteListColumn()
        .previewEnvironment()
        .frame(width: 320, height: 520)
        .preferredColorScheme(.dark)
}
