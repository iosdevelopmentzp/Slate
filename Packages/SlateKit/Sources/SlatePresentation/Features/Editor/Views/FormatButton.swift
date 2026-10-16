import SwiftUI
import SlateUI

struct FormatButton: View {
    let model: FormatButtonModel
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: model.systemImage)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(model.isActive ? Color.accentColor : Color.secondary)
                .frame(width: 28, height: 26)
                .background(background, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .focusable(false)
        .disabled(model.isEnabled == false)
        .opacity(model.isEnabled ? 1 : 0.4)
        .onHover { isHovered = $0 }
        .hint(model.hint)
        .accessibilityLabel(model.hint)
        .accessibilityAddTraits(model.isActive ? .isSelected : [])
    }

    private var background: Color {
        if model.isActive { return Color.accentColor.opacity(Theme.selectionOpacityLight) }
        return isHovered ? Theme.hover : .clear
    }
}

#Preview {
    FormatButton(model: .preview) {}
        .padding()
}
