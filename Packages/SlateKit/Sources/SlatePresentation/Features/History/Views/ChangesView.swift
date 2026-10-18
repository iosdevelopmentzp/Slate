import SwiftUI
import SlateDomain
import SlateUI

struct ChangesView: View {
    static let shownFiles = 6

    @Environment(VersionsStore.self) private var versions
    let folder: FolderPath
    let onOpen: (VaultPath) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Changes in \(folder.name)")
                .font(.headline)
            SaveVersionField { await versions.saveVersion($0) }
            if versions.isLoading, versions.changes.isEmpty {
                ProgressView().controlSize(.small)
            } else if versions.changes.isEmpty {
                Text("No changes yet. Slate saves a version every few minutes when something changed.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        let now = Date.now
                        ForEach(versions.changes) { change in
                            entry(change, now: now)
                        }
                    }
                }
                .frame(maxHeight: 360)
            }
            clearRow
        }
        .padding(12)
        .frame(width: 400)
        .task(id: folder) {
            await versions.loadChanges(in: folder)
        }
    }

    private func entry(_ change: SnapshotChange, now: Date) -> some View {
        let row = VersionRowMapper.model(for: change.snapshot, now: now)
        return VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(VersionRowMapper.summary(of: change))
                    .fontWeight(row.isNamed ? .semibold : .regular)
                    .lineLimit(1)
                Spacer(minLength: 4)
                if let badge = row.badge {
                    ModelTag(model: badge)
                }
                Text(change.snapshot.date.relativeDescription(to: now))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ForEach(Array(change.files.prefix(Self.shownFiles).enumerated()), id: \.offset) { _, file in
                Button {
                    onOpen(file.path)
                } label: {
                    Label(file.path.rawValue.dropFirst(folder.rawValue.count + 1).description, systemImage: icon(file.kind))
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .buttonStyle(.plain)
                .foregroundStyle(file.kind == .removed ? Color.secondary : Color.primary)
                .disabled(file.kind == .removed)
            }
            if change.files.count > Self.shownFiles {
                Text("and \(change.files.count - Self.shownFiles) more")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var clearRow: some View {
        if versions.confirmingClear == .folder(folder) {
            InlineConfirmation(
                "Remove every older version of \(folder.name)? Only the notes and files as they are now stay.",
                confirmTitle: "Clear History",
                confirmRole: .destructive,
                onCancel: { versions.cancelClear() },
                onConfirm: { Task { await versions.confirmClear() } }
            )
        } else {
            Button("Clear History of \(folder.name)…", role: .destructive) {
                versions.requestClear(.folder(folder))
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundStyle(Tint.red.color)
            .disabled(versions.isClearing)
        }
    }

    private func icon(_ kind: ChangedFile.Kind) -> String {
        switch kind {
        case .added: "plus.circle"
        case .changed: "pencil.circle"
        case .removed: "minus.circle"
        }
    }
}

#Preview("Light") {
    ChangesView(folder: FolderPath(rawValue: "Notes"), onOpen: { _ in })
        .previewEnvironment()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ChangesView(folder: FolderPath(rawValue: "Notes"), onOpen: { _ in })
        .previewEnvironment()
        .preferredColorScheme(.dark)
}
