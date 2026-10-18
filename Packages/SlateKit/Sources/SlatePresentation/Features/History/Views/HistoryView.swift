import SwiftUI
import SlateDomain
import SlateUI

struct HistoryView: View {
    @Environment(HistoryStore.self) private var history
    @Environment(VersionsStore.self) private var versions
    let path: VaultPath

    @State private var selected: String?
    @State private var showsChanges = true

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Versions")
                    .font(.headline)
                Spacer()
            }
            if history.isAvailable {
                SaveVersionField { name in
                    let saved = await versions.saveVersion(name)
                    if saved { await history.load(for: path) }
                    return saved
                }
            }
            content
        }
        .padding(12)
        .frame(width: history.snapshots.isEmpty ? 320 : 640)
        .task(id: path) {
            versions.clearPreview()
            selected = nil
            await history.load(for: path)
        }
    }

    @ViewBuilder
    private var content: some View {
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
            HStack(alignment: .top, spacing: 12) {
                list
                    .frame(width: 220)
                detail
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .frame(height: 340)
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 2) {
                let now = Date.now
                ForEach(history.snapshots) { snapshot in
                    VersionRow(model: VersionRowMapper.model(for: snapshot, now: now), isSelected: selected == snapshot.hash)
                        .onTapGesture {
                            selected = snapshot.hash
                            Task { await versions.select(snapshot, of: path) }
                        }
                }
            }
        }
    }

    @ViewBuilder
    private var detail: some View {
        if let preview = versions.preview, preview.snapshot.hash == selected {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Picker("Show", selection: $showsChanges) {
                        Text("Changes since").tag(true)
                        Text("Text").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .fixedSize()
                    Text(preview.added == 0 && preview.removed == 0 ? "Same as now" : "+\(preview.added) −\(preview.removed) lines")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Restore") {
                        Task { await history.restore(preview.snapshot, of: path) }
                    }
                    .controlSize(.small)
                }
                ScrollView {
                    if showsChanges {
                        DiffText(lines: preview.diff)
                    } else {
                        Text(preview.text.isEmpty ? " " : preview.text)
                            .font(.system(.callout, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .background(Theme.base, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                Text("Restore keeps the current text as a version too.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            Text("Pick a version to see it and what changed since.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
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
