import SwiftUI
import SlateDomain
import SlateUI

struct HeaderView: View {
    @Environment(NoteListStore.self) private var store
    @Environment(SearchStore.self) private var search
    @Environment(\.surface) private var surface
    @Environment(\.openAsWindow) private var openAsWindow
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        @Bindable var store = store
        @Bindable var search = search
        HStack(spacing: 8) {
            SpacePicker()
            SearchField(prompt: store.source == .trash ? "Search the Trash" : "Search", text: store.source == .trash ? $store.filterText : $search.query, focus: $isSearchFocused)
                .frame(maxWidth: .infinity)
                .onSubmit { search.openFirst() }
                .hint("Search notes (⌘F). Try tag:, type: or is:todo. Enter opens the first result, Esc clears.")
                .background(
                    Button("") { isSearchFocused = true }
                        .keyboardShortcut("f", modifiers: .command)
                        .opacity(0)
                        .allowsHitTesting(false)
                )
            NewNoteMenu()
            if surface == .panel {
                IconButton(systemImage: "macwindow", help: "Open as window (⌘⇧O)") {
                    openAsWindow()
                }
                .accessibilityLabel("Open as window")
            }
        }
        .controlSize(.regular)
        .padding(.horizontal, 12)
        .frame(height: 44)
        .background(PanelDragArea())
    }
}

#Preview("Light") {
    HeaderView()
        .previewEnvironment()
        .frame(width: 980)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    HeaderView()
        .previewEnvironment()
        .frame(width: 980)
        .preferredColorScheme(.dark)
}
