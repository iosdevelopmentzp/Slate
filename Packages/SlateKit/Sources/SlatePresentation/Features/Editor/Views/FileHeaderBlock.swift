import SwiftUI
import SlateUI

struct FileHeaderBlock: View {
    let lines: [String]
    let isOpaque: Bool
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation(Theme.hoverAnimation) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    Text("File header")
                    Text("· \(lines.count) \(lines.count == 1 ? "line" : "lines")")
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .font(.callout)
            .foregroundStyle(.secondary)
            .hint(isOpaque ? "Slate does not edit this header and keeps it as it is. Change it in another app." : "Fields Slate does not use. Slate keeps them as they are.")
            .accessibilityLabel(isExpanded ? "Hide file header" : "Show file header")
            if isExpanded {
                Text(lines.joined(separator: "\n"))
                    .font(.system(.callout, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Theme.codeBackground, in: RoundedRectangle(cornerRadius: Theme.fieldRadius))
                    .accessibilityLabel("File header")
            }
        }
    }
}

#Preview("Light") {
    FileHeaderBlock(lines: ["aliases:", "  - Trip", "cssclass: wide"], isOpaque: true, isExpanded: .constant(true))
        .padding()
        .frame(width: 480)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    FileHeaderBlock(lines: ["aliases:", "  - Trip", "cssclass: wide"], isOpaque: true, isExpanded: .constant(true))
        .padding()
        .frame(width: 480)
        .preferredColorScheme(.dark)
}
