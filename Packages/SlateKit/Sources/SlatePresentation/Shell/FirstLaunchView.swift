import SwiftUI
import SlateUI

struct FirstLaunchView: View {
    let defaultFolder: URL
    let problem: String?
    let onStart: (URL) -> Void

    @State private var folder: URL?

    var body: some View {
        let chosen = folder ?? defaultFolder
        VStack(alignment: .leading, spacing: 16) {
            Text("Where should Slate keep your notes?")
                .font(.title3.weight(.semibold))
            Text("Each note is a Markdown file in this folder. You can open the files in any editor.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                Image(systemName: "folder")
                    .foregroundStyle(.secondary)
                Text(chosen.path(percentEncoded: false))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .hintWhenTruncated(chosen.path(percentEncoded: false))
                Spacer(minLength: 8)
                Button("Choose…") {
                    let start = chosen.deletingLastPathComponent()
                    if let picked = FolderPicker.chooseFolder(directory: start, prompt: "Use this folder", message: "Choose the folder for your notes.") {
                        folder = picked
                    }
                }
            }
            .padding(10)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            if let problem {
                Label(problem, systemImage: "exclamationmark.triangle.fill")
                    .font(.callout)
                    .foregroundStyle(Tint.orange.color)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack {
                Spacer()
                Button("Start") { onStart(chosen) }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 480)
        .background(Theme.base)
    }
}

#Preview("Light") {
    FirstLaunchView(defaultFolder: URL(fileURLWithPath: "/Users/example/Documents/Slate"), problem: nil, onStart: { _ in })
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    FirstLaunchView(defaultFolder: URL(fileURLWithPath: "/Users/example/Documents/Slate"), problem: "Slate cannot use this folder. Choose another folder.", onStart: { _ in })
        .preferredColorScheme(.dark)
}
