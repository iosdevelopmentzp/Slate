import SwiftUI
import SlateDomain
import SlateEditor
import SlateUI

struct EditorView: View {
    @Environment(EditorStore.self) private var editor
    @Environment(SettingsStore.self) private var settings
    @Environment(Toaster.self) private var toaster
    @Environment(VaultStore.self) private var vault
    @State private var showsHistory = false
    @State private var commands = EditorCommands()
    @FocusState private var isTitleFocused: Bool

    @State private var showsSaved = false

    static let textWidth: CGFloat = 720
    static let sidePadding: CGFloat = 24

    var body: some View {
        if let document = editor.document {
            VStack(alignment: .leading, spacing: 0) {
                if editor.hasConflict {
                    ConflictBanner(
                        onKeepMine: { Task { await editor.keepMine() } },
                        onTakeTheirs: { Task { await editor.takeTheirs() } },
                        onOpenBoth: { Task { await editor.openBoth() } }
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                } else if let recovered = editor.recovered {
                    RecoveryBanner(
                        savedAt: recovered.savedAt.relativeDescription(to: .now),
                        onRestore: { editor.restoreRecovered() },
                        onDiscard: { editor.discardRecovered() }
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                header(for: document)
                    .frame(maxWidth: Self.textWidth + Self.sidePadding * 2)
                    .frame(maxWidth: .infinity)
                FormatBar(commands: commands)
                    .padding(.horizontal, Self.sidePadding)
                    .padding(.bottom, 8)
                    .frame(maxWidth: Self.textWidth + Self.sidePadding * 2, alignment: .leading)
                    .frame(maxWidth: .infinity)
                RichTextEditorView(
                    markdown: Bindable(editor).text,
                    configuration: EditorConfiguration(textSize: CGFloat(settings.editorFontSize)),
                    commands: commands,
                    focus: editor.bodyFocus.map { EditorFocusRequest(token: $0.token, atStart: $0.atStart, words: $0.words) },
                    insertion: editor.insertion.map { EditorInsertion(token: $0.token, markdown: $0.markdown) },
                    handlers: handlers,
                    collapsedSections: editor.collapsedSections
                )
                .padding(.horizontal, Self.sidePadding - 4 - RichTextEditorView.sideMargin)
                .frame(maxWidth: Self.textWidth + Self.sidePadding * 2)
                .frame(maxWidth: .infinity)
            }
            .overlay(alignment: .topTrailing) {
                saveIndicator
            }
            .animation(Theme.hoverAnimation, value: editor.hasConflict)
            .animation(Theme.hoverAnimation, value: editor.recovered)
            .background(Theme.surface)
            .onAppear {
                editor.flushBody = { [commands] in commands.flush() }
            }
            .onChange(of: editor.titleFocusToken) {
                isTitleFocused = true
            }
            .onChange(of: isTitleFocused) { wasFocused, isFocused in
                guard wasFocused, isFocused == false else { return }
                editor.titleEditingEnded()
            }
            .onChange(of: editor.saveState) { _, state in
                guard case .saved = state else { return }
                withAnimation(Theme.hoverAnimation) { showsSaved = true }
            }
            .task(id: showsSaved) {
                guard showsSaved else { return }
                try? await Task.sleep(for: .seconds(1))
                withAnimation(.easeOut(duration: 0.4)) { showsSaved = false }
            }
        } else {
            EmptyStateView(systemImage: "note.text", title: "Pick a note or press ⌘N.")
                .background(Theme.surface)
        }
    }

    @ViewBuilder
    private var saveIndicator: some View {
        if case .failed = editor.saveState {
            Label("Not saved", systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(Tint.orange.color)
                .padding(10)
                .hint("Slate could not save this note. See Activity in Settings.")
        } else if showsSaved {
            Text("Saved")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(10)
                .transition(.opacity)
                .accessibilityLabel("Saved")
        }
    }

    private func header(for document: NoteDocument) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            titleRow(for: document)
            if let task = TaskLineMapper.model(for: document.header, inProject: document.path.space.map(vault.isProject) ?? false) {
                TaskLine(model: task) { status in
                    Task { await editor.setStatus(status) }
                }
            }
        }
        .padding(.horizontal, Self.sidePadding)
        .padding(.top, 28)
        .padding(.bottom, 8)
    }

    private func titleRow(for document: NoteDocument) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            TextField("Title", text: titleBinding, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 24, weight: .bold))
                .lineLimit(1...2)
                .focused($isTitleFocused)
                .onSubmit { editor.submitTitle() }
                .disabled(document.isHeaderOpaque)
                .simultaneousGesture(TapGesture().modifiers(.option).onEnded { editor.copyPath() })
                .accessibilityLabel("Title")
            BacklinksButton(path: document.path)
            IconButton(systemImage: "list.bullet.indent", help: "Go to heading  ⇧⌘O") {
                commands.perform(.outline)
            }
            .accessibilityLabel("Headings")
            Menu {
                Button("Export as PDF") { Task { await editor.exportPDF() } }
                Button("Export as HTML") { Task { await editor.exportHTML() } }
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .menuIndicator(.hidden)
            .foregroundStyle(.secondary)
            .frame(width: 24, height: 24)
            .hint("Export the note to Downloads")
            .accessibilityLabel("Export")
            IconButton(systemImage: "clock.arrow.circlepath", help: "Versions of this note") {
                showsHistory.toggle()
            }
            .popover(isPresented: $showsHistory, arrowEdge: .bottom) {
                HistoryView(path: document.path)
            }
            .accessibilityLabel("Versions")
        }
    }

    private var handlers: EditorHandlers {
        let editor = editor
        return EditorHandlers(
            didEndEditing: { editor.bodyEditingEnded() },
            resolveImage: { editor.resolveLink($0) },
            openLink: { link in
                Task {
                    switch link {
                    case .url(let target): await editor.openURL(target)
                    case .wiki(let target): await editor.openWikilink(target)
                    }
                }
            },
            attachment: { link, action in
                switch action {
                case .quickLook: Task { await editor.attachment(link, quickLook: true) }
                case .open: Task { await editor.attachment(link, quickLook: false) }
                case .reveal: Task { await editor.reveal(link) }
                case .saveToDownloads: Task { await editor.saveToDownloads(link) }
                case .copyImage:
                    if let url = editor.resolveLink(link) { PasteboardWriter.writeImage(at: url) }
                }
            },
            pasteImage: { data, fileExtension in Task { await editor.pasteImage(data, fileExtension: fileExtension) } },
            pasteFiles: { urls in Task { await editor.pasteFiles(urls) } },
            requestScreenshot: { kind in Task { await editor.screenshot(kind == .region ? .region : .window) } },
            notice: { editor.toaster.show($0) },
            noteNames: { await editor.linkTargets() },
            collapsedSections: { editor.setCollapsedSections($0) }
        )
    }

    private var titleBinding: Binding<String> {
        Binding(get: { editor.titleFieldText }, set: { editor.editTitle($0) })
    }
}

#Preview("Light") {
    EditorView()
        .previewEnvironment()
        .frame(width: 640, height: 500)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    EditorView()
        .previewEnvironment()
        .frame(width: 640, height: 500)
        .preferredColorScheme(.dark)
}
