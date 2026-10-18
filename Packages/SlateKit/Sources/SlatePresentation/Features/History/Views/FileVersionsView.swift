import SwiftUI
import SlateDomain
import SlateUI

struct FileVersionsView: View {
    @Environment(VersionsStore.self) private var versions
    let path: VaultPath

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Versions of \(path.fileName)")
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.middle)
            if versions.isLoading, versions.fileVersions.isEmpty {
                ProgressView().controlSize(.small)
            } else if versions.fileVersions.isEmpty {
                Text("No versions yet. Files larger than 50 MB are not kept.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        let now = Date.now
                        ForEach(versions.fileVersions) { snapshot in
                            HStack {
                                VersionRow(model: VersionRowMapper.model(for: snapshot, now: now), isSelected: false)
                                Button("Quick Look") { Task { await versions.quickLook(snapshot, of: path) } }
                                Button("Restore") { Task { await versions.restoreFile(snapshot, of: path) } }
                            }
                            .controlSize(.small)
                        }
                    }
                }
                .frame(maxHeight: 280)
            }
        }
        .padding(12)
        .frame(width: 420)
        .task(id: path) {
            await versions.loadFileVersions(path)
        }
    }
}

#Preview("Light") {
    FileVersionsView(path: VaultPath(rawValue: "Notes/screen.png"))
        .previewEnvironment()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    FileVersionsView(path: VaultPath(rawValue: "Notes/screen.png"))
        .previewEnvironment()
        .preferredColorScheme(.dark)
}
