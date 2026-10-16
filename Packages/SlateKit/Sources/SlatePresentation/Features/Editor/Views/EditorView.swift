import SwiftUI
import SlateDomain
import SlateEditor
import SlateUI

struct EditorView: View {
    @Environment(EditorStore.self) private var editor
    @Environment(NoteListStore.self) private var noteList
    @Environment(SettingsStore.self) private var settings
    @Environment(Toaster.self) private var toaster
    @State private var showsHistory = false
    @FocusState private var isTitleFocused: Bool

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
                Divider()
                MarkdownEditorView(
                    text: Bindable(editor).text,
                    configuration: configuration,
                    focus: editor.bodyFocus.map { EditorFocusRequest(token: $0.token, caret: $0.caret) },
                    insertion: editor.insertion.map { EditorInsertion(token: $0.token, markdown: $0.markdown) },
                    handlers: handlers
                )
            }
            .animation(.easeInOut(duration: 0.15), value: editor.hasConflict)
            .animation(.easeInOut(duration: 0.15), value: editor.recovered)
            .background(Theme.surface)
            .onChange(of: editor.titleFocusToken) {
                isTitleFocused = true
            }
            .onChange(of: isTitleFocused) { wasFocused, isFocused in
                guard wasFocused, isFocused == false else { return }
                editor.titleEditingEnded()
            }
        } else {
            ContentUnavailableView("No note selected.", systemImage: "note.text", description: Text("Pick a note in the list or press ⌘N."))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.surface)
        }
    }

    private func header(for document: NoteDocument) -> some View {
        HStack(spacing: 6) {
            TextField(StemPolicy.untitled, text: titleBinding)
                .textFieldStyle(.plain)
                .font(.title3.weight(.semibold))
                .focused($isTitleFocused)
                .onSubmit { editor.submitTitle() }
                .disabled(document.isHeaderOpaque)
                .accessibilityLabel("Title")
            IconButton(systemImage: "clock.arrow.circlepath", help: "Versions of this note") {
                showsHistory.toggle()
            }
            .popover(isPresented: $showsHistory, arrowEdge: .bottom) {
                HistoryView(path: document.path)
            }
            .accessibilityLabel("Versions")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var configuration: EditorConfiguration {
        let size = CGFloat(settings.editorFontSize)
        return EditorConfiguration(
            proseFont: .systemFont(ofSize: size),
            codeFont: .monospacedSystemFont(ofSize: size - 1, weight: .regular),
            lineHeightMultiple: 1.35
        )
    }

    private var handlers: EditorHandlers {
        let editor = editor
        let noteList = noteList
        return EditorHandlers(
            didEndEditing: { editor.bodyEditingEnded() },
            resolveImage: { editor.resolveLink($0) },
            openLink: { link in
                Task {
                    switch link {
                    case .url(let target): await editor.openURL(target)
                    case .wiki(let target): await editor.openWikilink(target)
                    case .pattern: break
                    }
                }
            },
            attachment: { link, action in
                switch action {
                case .quickLook: Task { await editor.attachment(link, quickLook: true) }
                case .open: Task { await editor.attachment(link, quickLook: false) }
                case .reveal: Task { await editor.reveal(link) }
                case .copyImage:
                    if let url = editor.resolveLink(link) { PasteboardWriter.writeImage(at: url) }
                }
            },
            pasteImage: { data, fileExtension in Task { await editor.pasteImage(data, fileExtension: fileExtension) } },
            pasteFiles: { urls in Task { await editor.pasteFiles(urls) } },
            requestScreenshot: { kind in Task { await editor.screenshot(kind == .region ? .region : .window) } },
            completions: { kind, prefix in
                switch kind {
                case .note: CompletionPolicy.noteNames(matching: prefix, in: noteList.summaries)
                default: []
                }
            }
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
