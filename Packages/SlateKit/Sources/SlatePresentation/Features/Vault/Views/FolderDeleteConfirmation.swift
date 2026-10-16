import SwiftUI
import SlateUI

struct FolderDeleteConfirmation: View {
    let question: String
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(question)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 4) {
                Button("Yes", action: onConfirm)
                    .buttonStyle(.plain)
                    .fontWeight(.semibold)
                    .foregroundStyle(Tint.red.color)
                Text("·")
                    .foregroundStyle(.secondary)
                Button("No", action: onCancel)
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
            }
            .font(.callout)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Tint.red.color.opacity(0.08), in: RoundedRectangle(cornerRadius: Theme.pillRadius, style: .continuous))
        .onExitCommand(perform: onCancel)
    }
}

#Preview("Light") {
    FolderDeleteConfirmation(question: FolderRowModel.preview.deleteQuestion, onConfirm: {}, onCancel: {})
        .padding(8)
        .frame(width: 200)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    FolderDeleteConfirmation(question: FolderRowModel.preview.deleteQuestion, onConfirm: {}, onCancel: {})
        .padding(8)
        .frame(width: 200)
        .preferredColorScheme(.dark)
}
