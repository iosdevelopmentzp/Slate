import AppKit
import SwiftUI
import SlateDomain
import SlateUI

struct FooterView: View {
    @Environment(NoteListStore.self) private var store
    @Environment(\.surface) private var surface

    var body: some View {
        HStack(spacing: 8) {
            Text(CountText.count(store.visibleNotes.count, "note"))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Spacer()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.link)
            .font(.system(size: 11))
            .keyboardShortcut("q")
            if surface == .panel {
                ResizeGrip()
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 28)
        .background(PanelDragArea())
    }
}

#Preview("Light") {
    FooterView()
        .previewEnvironment()
        .frame(width: 980)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    FooterView()
        .previewEnvironment()
        .frame(width: 980)
        .preferredColorScheme(.dark)
}
