import SwiftUI
import SlateDomain
import SlateUI

struct NoteListColumn: View {
    @Environment(NoteListStore.self) private var store
    @Environment(SearchStore.self) private var search
    @Environment(WindowLayout.self) private var layout
    @Environment(EditorStore.self) private var editor
    @FocusState private var isSearchFocused: Bool
    @State private var showsChanges = false

    var body: some View {
        @Bindable var store = store
        @Bindable var search = search
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                if layout.showsSidebar == false {
                    IconButton(systemImage: "sidebar.left", help: "Show the folders (⌘0)") { layout.showsSidebar = true }
                        .accessibilityLabel("Show the folders")
                }
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
                    .hintWhenTruncated(title)
                Spacer(minLength: 8)
                if store.source != .trash {
                    sortMenu
                }
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
            .padding(.leading, layout.showsSidebar == false ? WindowLayout.trafficLightsWidth : 16)
            .padding(.trailing, Theme.columnPadding)
            .frame(height: 44)
            .background(HeaderDragArea())
            SearchField(prompt: store.source == .trash ? "Search the Trash" : "Search", text: store.source == .trash ? $store.filterText : $search.query, focus: $isSearchFocused)
                .onSubmit { search.openFirst() }
                .hint("Search all notes (⌘F, or ⇧⌘F from a note). Enter opens the first result, Esc clears.")
                .padding(.horizontal, Theme.columnPadding)
                .background(searchShortcuts)
            progressLine
            NoteListView()
        }
        .background(Theme.base)
    }

    private var sortMenu: some View {
        @Bindable var store = store
        return Menu {
            Picker("Sort By", selection: $store.sort) {
                ForEach(NoteSort.allCases, id: \.self) { sort in
                    Text(NoteSortMapper.title(for: sort)).tag(sort)
                }
            }
            .pickerStyle(.inline)
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .foregroundStyle(.secondary)
        .frame(width: 24, height: 24)
        .hint(NoteSortMapper.hint(for: store.sort))
        .accessibilityLabel("Sort notes")
    }

    private var searchShortcuts: some View {
        ZStack {
            searchShortcut("f", modifiers: .command) { findHere() }
            searchShortcut("f", modifiers: .control) { findHere() }
            searchShortcut("f", modifiers: [.command, .shift]) { focusSearch() }
        }
    }

    private func findHere() {
        guard editor.findInBody() == false else { return }
        focusSearch()
    }

    private func focusSearch() {
        layout.showsList = true
        isSearchFocused = true
    }

    private func searchShortcut(_ key: KeyEquivalent, modifiers: EventModifiers, action: @escaping () -> Void) -> some View {
        Button("", action: action)
            .keyboardShortcut(key, modifiers: modifiers)
            .opacity(0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
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
