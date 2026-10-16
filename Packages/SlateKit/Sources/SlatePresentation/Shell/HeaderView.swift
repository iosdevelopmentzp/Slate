import SwiftUI
import SlateDomain
import SlateUI

struct HeaderView: View {
    @Environment(NoteListStore.self) private var store
    @Environment(\.surface) private var surface
    @Environment(\.openAsWindow) private var openAsWindow
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        @Bindable var store = store
        HStack(spacing: 8) {
            SpacePicker()
            SearchField(prompt: "Search", text: $store.filterText, focus: $isSearchFocused)
                .frame(maxWidth: .infinity)
                .hint("Search note titles (⌘F). Esc clears.")
                .background(
                    Button("") { isSearchFocused = true }
                        .keyboardShortcut("f", modifiers: .command)
                        .opacity(0)
                        .allowsHitTesting(false)
                )
            if surface == .panel {
                IconButton(systemImage: "macwindow", help: "Open as window") {
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
