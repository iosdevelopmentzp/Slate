import SwiftUI
import SlateDomain
import SlateUI

struct HistoryView: View {
    @Environment(HistoryStore.self) private var history
    let path: VaultPath

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Versions")
                .font(.headline)
            if history.isAvailable == false {
                Text("Git is not installed, so Slate keeps no versions. Run xcode-select --install in Terminal.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else if history.isLoading, history.snapshots.isEmpty {
                ProgressView().controlSize(.small)
            } else if history.snapshots.isEmpty {
                Text("No versions yet. Slate saves one every \(history.settings.intervalMinutes) minutes when something changed.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(history.snapshots) { snapshot in
                            HistoryRow(snapshot: snapshot) {
                                Task { await history.restore(snapshot, of: path) }
                            }
                        }
                    }
                }
                .frame(maxHeight: 280)
                Text("Restore keeps the current text as a version too.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(width: 320)
        .task(id: path) {
            await history.load(for: path)
        }
    }
}

private struct HistoryRow: View {
    let snapshot: Snapshot
    let onRestore: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(snapshot.date.relativeDescription(to: .now))
                Text(snapshot.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Restore", action: onRestore)
                .controlSize(.small)
                .opacity(isHovered ? 1 : 0.6)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(isHovered ? Theme.hover : .clear, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        .onHover { isHovered = $0 }
    }
}

#Preview("Light") {
    HistoryView(path: VaultPath(rawValue: "Tasks/A.md"))
        .previewEnvironment()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    HistoryView(path: VaultPath(rawValue: "Tasks/A.md"))
        .previewEnvironment()
        .preferredColorScheme(.dark)
}
