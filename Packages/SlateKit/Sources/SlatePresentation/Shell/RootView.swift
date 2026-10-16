import SwiftUI
import SlateDomain
import SlateUI

struct RootView: View {
    @Environment(NoteListStore.self) private var noteList
    @Environment(Toaster.self) private var toaster
    @Environment(WindowLayout.self) private var layout
    @Environment(\.hintCenter) private var hintCenter
    @Environment(\.surface) private var surface

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
                    NoteDetailView()
                        .frame(minWidth: 320, maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                if let toast = toaster.text {
                    ToastView(text: toast)
                        .padding(.bottom, 12)
                }
            }
            .animation(.easeInOut(duration: 0.15), value: toaster.text)
            Divider()
            FooterView()
        }
        .background(sidebarShortcut)
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
    }

    @ViewBuilder
    private var sidebarShortcut: some View {
        if surface == .window {
            Button("") { showsSidebar.toggle() }
                .keyboardShortcut("0", modifiers: .command)
                .opacity(0)
                .allowsHitTesting(false)
        }
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
