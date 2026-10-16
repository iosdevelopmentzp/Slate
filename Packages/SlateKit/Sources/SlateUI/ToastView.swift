import SwiftUI

package struct ToastView: View {
    package let text: String
    package let actionTitle: String?
    package let action: () -> Void

    package init(text: String, actionTitle: String? = nil, action: @escaping () -> Void = {}) {
        self.text = text
        self.actionTitle = actionTitle
        self.action = action
    }

    package var body: some View {
        HStack(spacing: 10) {
            Text(text)
                .lineLimit(1)
            if let actionTitle {
                Button(actionTitle, action: action)
                    .buttonStyle(.plain)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accentColor)
            }
        }
        .font(.callout)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .shadow(color: Theme.softShadow, radius: 12, y: 4)
        .transition(.opacity)
    }
}

#Preview("Light") {
    VStack(spacing: 12) {
        ToastView(text: "Saved to Notes")
        ToastView(text: "Moved to the Trash", actionTitle: "Undo")
    }
    .padding()
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    VStack(spacing: 12) {
        ToastView(text: "Saved to Notes")
        ToastView(text: "Moved to the Trash", actionTitle: "Undo")
    }
    .padding()
    .preferredColorScheme(.dark)
}
