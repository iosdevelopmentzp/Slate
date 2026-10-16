import SwiftUI
import SlateUI

struct ConflictBanner: View {
    let onKeepMine: () -> Void
    let onTakeTheirs: () -> Void
    let onOpenBoth: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Label("Changed on disk. Your text is not saved yet.", systemImage: "exclamationmark.triangle.fill")
                .font(.callout)
                .lineLimit(1)
            Spacer(minLength: 8)
            Button("Keep mine", action: onKeepMine)
            Button("Take theirs", action: onTakeTheirs)
            Button("Open both", action: onOpenBoth)
                .help("Keeps your text as a new note and shows the version on disk")
        }
        .controlSize(.small)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Tint.orange.color.opacity(0.14))
    }
}

#Preview("Light") {
    ConflictBanner(onKeepMine: {}, onTakeTheirs: {}, onOpenBoth: {})
        .frame(width: 640)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ConflictBanner(onKeepMine: {}, onTakeTheirs: {}, onOpenBoth: {})
        .frame(width: 640)
        .preferredColorScheme(.dark)
}
