import SwiftUI
import SlateDomain
import SlateEditor
import SlateUI

struct FileViewerView: View {
    @Environment(FileViewerStore.self) private var viewer
    @Environment(FolderFilesStore.self) private var files
    @Environment(SettingsStore.self) private var settings
    @State private var showsVersions = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if viewer.hasConflict {
                ConflictBanner(
                    onKeepMine: { Task { await viewer.keepMine() } },
                    onTakeTheirs: { Task { await viewer.takeTheirs() } }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            if let path = viewer.path, let meta = viewer.meta {
                header(path: path, meta: meta)
            }
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .animation(Theme.hoverAnimation, value: viewer.hasConflict)
        .background(Theme.surface)
    }

    private func header(path: VaultPath, meta: FileMeta) -> some View {
        HStack(alignment: .center, spacing: 10) {
            FileThumbnail(url: files.url(for: path), isImage: AttachmentPolicy.isImage(path.fileName))
            VStack(alignment: .leading, spacing: 2) {
                Text(path.fileName)
                    .font(.system(size: 20, weight: .bold))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
                Text(FileRowMapper.viewerDetail(for: meta, content: viewer.content, now: .now))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            IconButton(systemImage: "eye", help: "Quick Look") {
                Task { await files.quickLook(path) }
            }
            .accessibilityLabel("Quick Look")
            IconButton(systemImage: "arrow.up.forward.app", help: "Open in its app") {
                Task { await files.open(path) }
            }
            .accessibilityLabel("Open")
            IconButton(systemImage: "folder", help: "Show in Finder") {
                Task { await files.reveal(path) }
            }
            .accessibilityLabel("Show in Finder")
            IconButton(systemImage: "clock.arrow.circlepath", help: "Versions of this file") {
                showsVersions.toggle()
            }
            .popover(isPresented: $showsVersions, arrowEdge: .bottom) {
                FileVersionsView(path: path)
            }
            .accessibilityLabel("Versions")
        }
        .padding(.horizontal, EditorView.sidePadding)
        .padding(.top, 28)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private var content: some View {
        switch viewer.content {
        case .loading:
            ProgressView()
                .controlSize(.small)
        case .text:
            PlainTextEditorView(
                text: Bindable(viewer).text,
                textSize: CGFloat(settings.editorFontSize) - 1,
                resetToken: viewer.textToken
            )
        case .preview:
            if let url = viewer.url {
                FilePreview(url: url, token: viewer.previewToken)
            }
        case .missing:
            EmptyStateView(systemImage: "questionmark.folder", title: "This file is gone.")
        }
    }
}

#Preview("Light") {
    FileViewerView()
        .previewEnvironment()
        .frame(width: 640, height: 480)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    FileViewerView()
        .previewEnvironment()
        .frame(width: 640, height: 480)
        .preferredColorScheme(.dark)
}
