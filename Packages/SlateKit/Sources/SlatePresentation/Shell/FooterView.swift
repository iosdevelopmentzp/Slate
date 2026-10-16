import AppKit
import SwiftUI
import SlateDomain
import SlateUI

struct FooterView: View {
    @Environment(NoteListStore.self) private var store
    @Environment(EditorStore.self) private var editor
    @Environment(\.surface) private var surface

    var body: some View {
        HStack(spacing: 8) {
            TimelineView(.periodic(from: .now, by: 30)) { context in
                Text(status(now: context.date))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
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

    private func status(now: Date) -> String {
        let count = store.source == .trash ? store.visibleTrash.count : store.visibleNotes.count
        let parts = [CountText.count(count, "note"), SaveStatusText.text(for: editor.saveState, now: now)]
        return parts.compactMap { $0 }.joined(separator: " · ")
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
