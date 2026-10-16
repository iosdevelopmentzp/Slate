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
        .padding(.vertical, 8)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Theme.border))
        .shadow(color: Theme.shadow, radius: 6, y: 2)
        .transition(.opacity)
    }
}

#Preview("Light") {
    VStack(spacing: 12) {
        ToastView(text: "Branch copied")
        ToastView(text: "Moved to the Trash", actionTitle: "Undo")
    }
    .padding()
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    VStack(spacing: 12) {
        ToastView(text: "Branch copied")
        ToastView(text: "Moved to the Trash", actionTitle: "Undo")
    }
    .padding()
    .preferredColorScheme(.dark)
}
