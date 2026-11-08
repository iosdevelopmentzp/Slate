import SwiftUI
import SlateUI

struct AgentChangeBanner: View {
    let changedAt: String
    let onShowChanges: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Label("An agent changed this note \(changedAt).", systemImage: "sparkles")
                .font(.callout)
                .lineLimit(1)
            Spacer(minLength: 8)
            Button("Show Changes", action: onShowChanges)
            Button("Got It", action: onDismiss)
        }
        .controlSize(.small)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Tint.purple.color.opacity(0.12), in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.top, PanelToggles.height + 8)
    }
}

#Preview("Light") {
    AgentChangeBanner(changedAt: "5 min. ago", onShowChanges: {}, onDismiss: {})
        .frame(width: 640)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    AgentChangeBanner(changedAt: "5 min. ago", onShowChanges: {}, onDismiss: {})
        .frame(width: 640)
        .preferredColorScheme(.dark)
}
