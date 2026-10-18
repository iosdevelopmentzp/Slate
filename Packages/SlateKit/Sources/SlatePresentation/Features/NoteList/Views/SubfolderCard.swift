import SwiftUI
import SlateDomain
import SlateUI

struct SubfolderCard: View {
    let model: FolderRowModel
    let isDropTarget: Bool

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: model.status == nil ? "folder.fill" : "checkmark.circle.fill")
                .font(.system(size: 15))
                .foregroundStyle(model.status.map { $0.tint.color } ?? model.tint.color)
                .accessibilityHidden(true)
            Text(model.title)
                .font(.body.weight(.medium))
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 4)
            if let status = model.status {
                ModelTag(model: status)
            }
            Text("\(model.count)")
                .font(.callout)
                .foregroundStyle(.secondary)
                .monospacedDigit()
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, Theme.cardPadding)
        .frame(height: 40)
        .softPill(isSelected: isDropTarget, isHovered: isHovered, radius: Theme.cardRadius, base: Theme.surface)
        .contentShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .onHover { isHovered = $0 }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Opens the folder")
    }
}

#Preview("Light") {
    SubfolderCard(model: .preview, isDropTarget: false)
        .padding()
        .frame(width: 320)
        .preferredColorScheme(.light)
}

#Preview("Task") {
    SubfolderCard(model: .taskPreview, isDropTarget: false)
        .padding()
        .frame(width: 320)
}

#Preview("Dark") {
    SubfolderCard(model: .preview, isDropTarget: true)
        .padding()
        .frame(width: 320)
        .preferredColorScheme(.dark)
}
