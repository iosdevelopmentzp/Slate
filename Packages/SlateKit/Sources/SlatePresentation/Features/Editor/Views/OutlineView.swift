import SwiftUI
import SlateEditor
import SlateUI

struct OutlineView: View {
    let items: [OutlineItem]
    let onSelect: (OutlineItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Outline")
                .font(.headline)
            if items.isEmpty {
                Text("This note has no headings. Start a line with # to add one.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(items) { item in
                            Button {
                                onSelect(item)
                            } label: {
                                Text(item.title)
                                    .lineLimit(1)
                                    .padding(.leading, CGFloat(max(item.level - 1, 0)) * 12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 3)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxHeight: 320)
            }
        }
        .padding(12)
        .frame(width: 280)
    }
}

#Preview("Light") {
    OutlineView(items: OutlineItem.items(in: "# Plan\n## Context\n### Detail\n## Findings"), onSelect: { _ in })
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    OutlineView(items: OutlineItem.items(in: "# Plan\n## Context"), onSelect: { _ in })
        .preferredColorScheme(.dark)
}
