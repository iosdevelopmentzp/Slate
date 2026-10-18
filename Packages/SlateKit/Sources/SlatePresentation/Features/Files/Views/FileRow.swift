import SwiftUI
import SlateDomain
import SlateUI

struct FileRow: View {
    let model: FileRowModel
    let url: URL
    let actions: FileRowActions

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            FileThumbnail(url: url, isImage: model.isImage)
            VStack(alignment: .leading, spacing: 1) {
                Text(model.name)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(model.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            OverflowMenu {
                FileRowMenu(actions: actions)
            }
            .opacity(isHovered ? 1 : 0)
            .accessibilityLabel("More for \(model.name)")
        }
        .padding(.horizontal, Theme.cardPadding)
        .padding(.vertical, 6)
        .softPill(isSelected: false, isHovered: isHovered, radius: Theme.cardRadius, base: Theme.surface)
        .contentShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .onHover { isHovered = $0 }
        .onTapGesture(count: 2, perform: actions.quickLook)
        .contextMenu {
            FileRowMenu(actions: actions)
        }
        .onDrag(actions.drag)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(model.name)
        .accessibilityHint("Double click to look at the file")
    }
}

#Preview("Light") {
    FileRow(model: .preview, url: URL(fileURLWithPath: "/tmp/crash.log"), actions: .preview)
        .padding()
        .frame(width: 320)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    FileRow(model: .preview, url: URL(fileURLWithPath: "/tmp/crash.log"), actions: .preview)
        .padding()
        .frame(width: 320)
        .preferredColorScheme(.dark)
}
