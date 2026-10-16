import SwiftUI
import SlateUI

struct RecoveryBanner: View {
    let savedAt: String
    let onRestore: () -> Void
    let onDiscard: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Label("Unsaved text from \(savedAt) was found.", systemImage: "clock.arrow.circlepath")
                .font(.callout)
                .lineLimit(1)
            Spacer(minLength: 8)
            Button("Restore", action: onRestore)
            Button("Discard", action: onDiscard)
        }
        .controlSize(.small)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Tint.blue.color.opacity(0.12), in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

#Preview("Light") {
    RecoveryBanner(savedAt: "10:42", onRestore: {}, onDiscard: {})
        .frame(width: 640)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    RecoveryBanner(savedAt: "10:42", onRestore: {}, onDiscard: {})
        .frame(width: 640)
        .preferredColorScheme(.dark)
}
