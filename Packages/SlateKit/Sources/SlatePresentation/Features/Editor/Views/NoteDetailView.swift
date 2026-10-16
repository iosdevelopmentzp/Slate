import SwiftUI
import SlateDomain
import SlateEditor
import SlateUI

struct NoteDetailView: View {
    @Environment(NoteListStore.self) private var store

    @State private var text = ""

    var body: some View {
        if let note = store.selected {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(note.title)
                        .font(.title3.weight(.semibold))
                        .lineLimit(1)
                        .hintWhenTruncated(note.title)
                    FlowLayout(spacing: 6) {
                        if let status = note.status {
                            Tag(NoteStatusText.title(status), tint: NoteStatusText.tint(status).color)
                        }
                        if let ticket = note.ticket {
                            Tag(ticket, tint: .blue, systemImage: "ticket")
                        }
                        if let space = note.space {
                            Tag(space.rawValue, systemImage: "folder")
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                Divider()
                MarkdownEditorView(text: $text, configuration: .standard)
            }
            .background(Theme.surface)
            .onChange(of: note.id, initial: true) {
                text = note.preview
            }
        } else {
            ContentUnavailableView("No note selected.", systemImage: "note.text", description: Text("Pick a note in the list."))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.surface)
        }
    }
}

#Preview("Light") {
    NoteDetailView()
        .previewEnvironment()
        .frame(width: 640, height: 500)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    NoteDetailView()
        .previewEnvironment()
        .frame(width: 640, height: 500)
        .preferredColorScheme(.dark)
}
