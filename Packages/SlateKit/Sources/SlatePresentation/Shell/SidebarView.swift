import SwiftUI
import SlateDomain
import SlateUI

struct SidebarView: View {
    @Environment(NoteListStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                Text("Folders")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 4)
                row("All notes", systemImage: "tray.full", space: nil)
                ForEach(store.spaces) { space in
                    row(space.folder.rawValue, systemImage: space.icon ?? "folder", space: space.folder)
                }
            }
            .padding(8)
        }
        .frame(maxHeight: .infinity)
        .background(Theme.base)
    }

    private func row(_ title: String, systemImage: String, space: SpaceName?) -> some View {
        let isSelected = store.space == space
        return HStack(spacing: 8) {
            Label(title, systemImage: systemImage)
                .lineLimit(1)
            Spacer(minLength: 4)
            Text("\(store.count(in: space))")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isSelected ? Theme.selection.opacity(0.18) : .clear, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture { store.show(space: space) }
    }
}

#Preview("Light") {
    SidebarView()
        .previewEnvironment(surface: .window)
        .frame(width: 200, height: 400)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    SidebarView()
        .previewEnvironment(surface: .window)
        .frame(width: 200, height: 400)
        .preferredColorScheme(.dark)
}
