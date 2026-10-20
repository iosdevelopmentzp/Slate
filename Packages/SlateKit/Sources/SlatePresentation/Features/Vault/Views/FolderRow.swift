import SwiftUI
import SlateDomain
import SlateUI

struct FolderRow: View {
    enum Disclosure {
        case none
        case empty
        case collapsed
        case expanded
    }

    let title: String
    let icon: String
    let tint: Color
    let count: Int?
    let isSelected: Bool
    let isDropTarget: Bool
    var level: Int = 0
    var disclosure: Disclosure = .none
    var onToggle: () -> Void = {}

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 6) {
            if disclosure != .none {
                disclosureButton
            }
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(tint)
                .frame(width: 18)
                .accessibilityHidden(true)
            Text(title)
                .lineLimit(1)
                .truncationMode(.tail)
                .hintWhenTruncated(title)
            Spacer(minLength: 4)
            if let count {
                Text("\(count)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(.leading, 8 + CGFloat(level) * 14)
        .padding(.trailing, 8)
        .frame(height: 30)
        .softPill(isSelected: isSelected || isDropTarget, isHovered: isHovered)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    @ViewBuilder
    private var disclosureButton: some View {
        if disclosure == .empty {
            Color.clear.frame(width: 12, height: 12)
        } else {
            Button(action: onToggle) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(disclosure == .expanded ? 90 : 0))
                    .frame(width: 12, height: 12)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .animation(Theme.hoverAnimation, value: disclosure)
            .accessibilityLabel(disclosure == .expanded ? "Hide sub-folders" : "Show sub-folders")
        }
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
