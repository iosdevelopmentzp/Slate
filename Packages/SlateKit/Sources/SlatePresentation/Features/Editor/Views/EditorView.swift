import SwiftUI
import SlateDomain
import SlateEditor
import SlateUI

struct EditorView: View {
    @Environment(EditorStore.self) private var editor
    @Environment(VaultStore.self) private var vault
    @FocusState private var isTitleFocused: Bool

    var body: some View {
        if let document = editor.document {
            VStack(alignment: .leading, spacing: 0) {
                if editor.hasConflict {
                    ConflictBanner(
                        onKeepMine: { Task { await editor.keepMine() } },
                        onTakeTheirs: { Task { await editor.takeTheirs() } }
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                header(for: document)
                Divider()
                MarkdownEditorView(
                    text: Bindable(editor).text,
                    configuration: .standard,
                    focus: editor.bodyFocus.map { EditorFocusRequest(token: $0.token, caret: $0.caret) },
                    handlers: EditorHandlers(didEndEditing: { editor.bodyEditingEnded() })
                )
            }
            .animation(.easeInOut(duration: 0.15), value: editor.hasConflict)
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
        VStack(alignment: .leading, spacing: 6) {
            TextField(StemPolicy.untitled, text: titleBinding)
                .textFieldStyle(.plain)
                .font(.title3.weight(.semibold))
                .focused($isTitleFocused)
                .onSubmit { editor.submitTitle() }
                .disabled(document.isHeaderOpaque)
                .accessibilityLabel("Title")
            let chips = NoteChipsMapper.chips(for: document, type: vault.type(named: document.type))
            if chips.isEmpty == false {
                FlowLayout(spacing: 6) {
                    ForEach(chips, id: \.self) { chip in
                        ModelTag(model: chip)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
