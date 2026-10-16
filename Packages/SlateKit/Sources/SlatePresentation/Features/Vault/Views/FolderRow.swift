import SwiftUI
import SlateDomain
import SlateUI

struct FolderRow: View {
    let title: String
    let icon: String
    let tint: Color
    let count: Int?
    let isSelected: Bool
    let isDropTarget: Bool

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(tint)
                .frame(width: 18)
                .accessibilityHidden(true)
            Text(title)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 4)
            if let count {
                Text("\(count)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 30)
        .softPill(isSelected: isSelected || isDropTarget, isHovered: isHovered)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview("Light") {
    VStack(spacing: 2) {
        FolderRow(title: "Notes", icon: "folder.fill", tint: .blue, count: 12, isSelected: true, isDropTarget: false)
        FolderRow(title: "Ideas", icon: "lightbulb.fill", tint: .yellow, count: 4, isSelected: false, isDropTarget: false)
        FolderRow(title: "Trash", icon: "trash", tint: .secondary, count: nil, isSelected: false, isDropTarget: false)
    }
    .padding(8)
    .frame(width: 200)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    VStack(spacing: 2) {
        FolderRow(title: "Notes", icon: "folder.fill", tint: .blue, count: 12, isSelected: true, isDropTarget: false)
        FolderRow(title: "Ideas", icon: "lightbulb.fill", tint: .yellow, count: 4, isSelected: false, isDropTarget: true)
    }
    .padding(8)
    .frame(width: 200)
    .preferredColorScheme(.dark)
}
