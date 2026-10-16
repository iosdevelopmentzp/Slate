import AppKit
import SwiftUI
import SlateDomain
import SlateUI

struct FooterView: View {
    @Environment(NoteListStore.self) private var store
    @Environment(EditorStore.self) private var editor
    @Environment(HistoryStore.self) private var history
    @Environment(ActivityLog.self) private var activity
    @Environment(\.surface) private var surface
    @State private var showsActivity = false

    var body: some View {
        HStack(spacing: 8) {
            TimelineView(.periodic(from: .now, by: 30)) { context in
                Text(status(now: context.date))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            if let pushFailed = pushFailureText {
                Button(pushFailed) { showsActivity = true }
                    .buttonStyle(.link)
                    .font(.system(size: 11))
                    .foregroundStyle(Tint.orange.color)
            }
            Spacer()
            Button(activityTitle) { showsActivity.toggle() }
                .buttonStyle(.link)
                .font(.system(size: 11))
                .popover(isPresented: $showsActivity, arrowEdge: .top) {
                    ActivityView()
                }
                .accessibilityLabel("Activity")
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

    private var pushFailureText: String? {
        if case .failed = history.push { return "push failed" }
        return nil
    }

    private var activityTitle: String {
        let failures = activity.events.filter { $0.outcome == .failure }.count
        return failures == 0 ? "Activity" : "Activity (\(failures))"
    }

    private func status(now: Date) -> String {
        let count = store.source == .trash ? store.visibleTrash.count : store.visibleNotes.count
        let snapshot = history.lastSnapshot.map { "history \(LogTimestamp.time($0))" }
        let pushed = history.push == .pushed ? "pushed" : nil
        let parts = [CountText.count(count, "note"), SaveStatusText.text(for: editor.saveState, now: now), snapshot, pushed]
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
