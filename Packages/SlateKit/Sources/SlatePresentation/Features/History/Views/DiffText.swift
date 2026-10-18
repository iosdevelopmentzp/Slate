import SwiftUI
import SlateDomain
import SlateUI

struct DiffText: View {
    let lines: [DiffLine]

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(mark(line.kind))
                        .foregroundStyle(tint(line.kind))
                        .frame(width: 10)
                        .accessibilityHidden(true)
                    Text(line.text.isEmpty ? " " : line.text)
                        .foregroundStyle(line.kind == .same ? Color.secondary : Color.primary)
                        .strikethrough(line.kind == .removed, color: tint(.removed).opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .font(.system(.callout, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 1)
                .background(line.kind == .same ? Color.clear : tint(line.kind).opacity(0.12))
                .accessibilityLabel(label(line))
            }
        }
        .textSelection(.enabled)
    }

    private func mark(_ kind: DiffLine.Kind) -> String {
        switch kind {
        case .same: " "
        case .added: "+"
        case .removed: "−"
        }
    }

    private func tint(_ kind: DiffLine.Kind) -> Color {
        switch kind {
        case .same: .secondary
        case .added: Tint.green.color
        case .removed: Tint.red.color
        }
    }

    private func label(_ line: DiffLine) -> String {
        switch line.kind {
        case .same: line.text
        case .added: "Added: \(line.text)"
        case .removed: "Removed: \(line.text)"
        }
    }
}

#Preview("Light") {
    DiffText(lines: [DiffLine(.same, "## Plan"), DiffLine(.removed, "- [ ] old step"), DiffLine(.added, "- [x] new step")])
        .padding()
        .frame(width: 360)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    DiffText(lines: [DiffLine(.same, "## Plan"), DiffLine(.removed, "- [ ] old step"), DiffLine(.added, "- [x] new step")])
        .padding()
        .frame(width: 360)
        .preferredColorScheme(.dark)
}
