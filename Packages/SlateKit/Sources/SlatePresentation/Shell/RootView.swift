import SwiftUI
import SlateDomain
import SlateUI

struct RootView: View {
    @Environment(NoteListStore.self) private var noteList
    @Environment(EditorStore.self) private var editor
    @Environment(Navigator.self) private var navigator
    @Environment(Toaster.self) private var toaster
    @Environment(WindowLayout.self) private var layout
    @Environment(VaultStore.self) private var vault
    @Environment(SearchStore.self) private var search
    @Environment(\.hintCenter) private var hintCenter
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        HStack(spacing: 0) {
            if layout.showsSidebar {
                SidebarView()
                    .frame(width: layout.sidebarWidth)
                    .overlay(alignment: .trailing) {
                        ColumnResizer(column: .sidebar)
                    }
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
            NoteListColumn()
                .frame(width: layout.listWidth)
                .padding(.leading, layout.showsSidebar ? 0 : 4)
                .frame(width: layout.showsList ? nil : 0, alignment: .leading)
                .clipped()
                .opacity(layout.showsList ? 1 : 0)
                .allowsHitTesting(layout.showsList)
                .accessibilityHidden(layout.showsList == false)
            if layout.showsList {
                ColumnResizer(column: .list)
                    .background(Theme.base)
            }
            EditorView()
                .frame(minWidth: 320, maxWidth: .infinity)
                .overlay(alignment: .topLeading) {
                    PanelToggles()
                }
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: Theme.panelRadius, bottomLeadingRadius: Theme.panelRadius, style: .continuous))
                .padding(.leading, layout.showsSidebar || layout.showsList ? 0 : 4)
        }
        .animation(Theme.sidebarAnimation, value: layout.showsSidebar)
        .animation(Theme.sidebarAnimation, value: layout.showsList)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.base)
        .overlay(alignment: .bottom) {
            if let toast = toaster.text {
                ToastView(text: toast, actionTitle: toaster.actionTitle) {
                    toaster.performAction()
                }
                .padding(.bottom, 16)
            }
        }
        .animation(Theme.hoverAnimation, value: toaster.text)
        .background(shortcuts)
        .overlay {
            if let hintCenter {
                HintOverlay(center: hintCenter)
            }
        }
        .modifier(WindowFrame(layout: layout))
        .task(id: layout.openCount) {
            await noteList.refresh()
        }
        .onChange(of: noteList.source) {
            layout.showsList = true
        }
        .onChange(of: navigator.selectedNote, initial: true) { _, id in
            Task { await editor.open(id) }
        }
    }

    private var shortcuts: some View {
        ZStack {
            shortcut("n", modifiers: .command) { Task { await noteList.createNote() } }
            shortcut("n", modifiers: [.command, .shift]) { newFolder() }
            shortcut("p", modifiers: [.command, .shift]) {
                guard let selected = noteList.selected else { return }
                Task { await noteList.togglePin(selected) }
            }
            shortcut(",", modifiers: .command) { openSettings() }
            shortcut("0", modifiers: .command) { layout.showsSidebar.toggle() }
            shortcut("0", modifiers: [.command, .option]) { layout.showsList.toggle() }
            shortcut("[", modifiers: [.command, .shift]) { noteList.show(ListSource.cycle(from: noteList.source, spaces: vault.spaces.map(\.folder), by: -1)) }
            shortcut("]", modifiers: [.command, .shift]) { noteList.show(ListSource.cycle(from: noteList.source, spaces: vault.spaces.map(\.folder), by: 1)) }
            shortcut(.upArrow, modifiers: [.command, .option]) { selectNeighbour(-1) }
            shortcut(.downArrow, modifiers: [.command, .option]) { selectNeighbour(1) }
            shortcut(.upArrow, modifiers: .command) {
                if TextFocus.isEditingText { TextFocus.send(#selector(NSResponder.moveToBeginningOfDocument(_:))) } else { selectNeighbour(-1) }
            }
            shortcut(.downArrow, modifiers: .command) {
                if TextFocus.isEditingText { TextFocus.send(#selector(NSResponder.moveToEndOfDocument(_:))) } else { selectNeighbour(1) }
            }
            shortcut(.delete, modifiers: .command) {
                if TextFocus.isEditingText {
                    TextFocus.send(#selector(NSResponder.deleteToBeginningOfLine(_:)))
                } else if let selected = noteList.selected {
                    noteList.requestTrash(selected.id)
                }
            }
            ForEach(Array(vault.spaces.prefix(9).enumerated()), id: \.element.id) { position, space in
                shortcut(KeyEquivalent(Character("\(position + 1)")), modifiers: .command) { noteList.show(.space(space.folder)) }
            }
        }
    }

    private func newFolder() {
        layout.showsSidebar = true
        vault.startNewFolder()
    }

    private func selectNeighbour(_ offset: Int) {
        noteList.selectNeighbour(offset, in: search.isActive ? search.results.map(\.summary) : nil)
    }

    private func shortcut(_ key: KeyEquivalent, modifiers: EventModifiers, action: @escaping () -> Void) -> some View {
        Button("", action: action)
            .keyboardShortcut(key, modifiers: modifiers)
            .opacity(0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

#Preview("Light") {
    RootView()
        .previewEnvironment()
        .frame(width: 1040, height: 680)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    RootView()
        .previewEnvironment()
        .frame(width: 1040, height: 680)
        .preferredColorScheme(.dark)
}
