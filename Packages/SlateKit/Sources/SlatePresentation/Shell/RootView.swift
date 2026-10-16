import SwiftUI
import SlateDomain
import SlateUI

struct RootView: View {
    @Environment(NoteListStore.self) private var noteList
    @Environment(EditorStore.self) private var editor
    @Environment(Navigator.self) private var navigator
    @Environment(Toaster.self) private var toaster
    @Environment(WindowLayout.self) private var layout
    @Environment(\.hintCenter) private var hintCenter
    @Environment(\.surface) private var surface
    @Environment(\.openAsWindow) private var openAsWindow
    @Environment(\.openSettings) private var openSettings
    @Environment(DailyStore.self) private var daily

    @State private var showsSidebar = true

    var body: some View {
        VStack(spacing: 0) {
            HeaderView()
            Divider()
            HStack(spacing: 0) {
                if surface == .window, showsSidebar {
                    SidebarView()
                        .frame(width: 200)
                    Divider()
                }
                HSplitView {
                    NoteListView()
                        .frame(minWidth: 240, idealWidth: 300, maxWidth: 400)
                    EditorView()
                        .frame(minWidth: 320, maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                if let toast = toaster.text {
                    ToastView(text: toast, actionTitle: toaster.actionTitle) {
                        toaster.performAction()
                    }
                    .padding(.bottom, 12)
                }
            }
            .animation(.easeInOut(duration: 0.15), value: toaster.text)
            Divider()
            FooterView()
        }
        .background(shortcuts)
        .overlay {
            if let hintCenter {
                HintOverlay(center: hintCenter)
            }
        }
        .modifier(WindowFrame(layout: layout, surface: surface))
        .background(Theme.base)
        .clipShape(RoundedRectangle(cornerRadius: surface == .panel ? 10 : 0, style: .continuous))
        .task(id: layout.openCount) {
            await noteList.refresh()
        }
        .onChange(of: navigator.selectedNote, initial: true) { _, id in
            Task { await editor.open(id) }
        }
    }

    private var shortcuts: some View {
        ZStack {
            shortcut("n", modifiers: .command) { Task { await noteList.createNote() } }
            shortcut("t", modifiers: [.command, .shift]) { Task { await noteList.createNote(type: NoteType.task.name) } }
            shortcut("p", modifiers: [.command, .shift]) {
                guard let selected = noteList.selected else { return }
                Task { await noteList.togglePin(selected) }
            }
            shortcut("d", modifiers: [.command, .shift]) { Task { await editor.markDone() } }
            shortcut("[", modifiers: .command) { Task { await daily.openDay(-1) } }
            shortcut("]", modifiers: .command) { Task { await daily.openDay(1) } }
            shortcut(",", modifiers: .command) { openSettings() }
            if surface == .panel {
                shortcut("o", modifiers: [.command, .shift]) { openAsWindow() }
            }
            if surface == .window {
                shortcut("0", modifiers: .command) { showsSidebar.toggle() }
            }
        }
    }

    private func shortcut(_ key: KeyEquivalent, modifiers: EventModifiers, action: @escaping () -> Void) -> some View {
        Button("", action: action)
            .keyboardShortcut(key, modifiers: modifiers)
            .opacity(0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

#Preview("Panel, light") {
    RootView()
        .previewEnvironment()
        .preferredColorScheme(.light)
}

#Preview("Panel, dark") {
    RootView()
        .previewEnvironment()
        .preferredColorScheme(.dark)
}

#Preview("Window") {
    RootView()
        .previewEnvironment(surface: .window)
        .frame(width: 1180, height: 680)
}
