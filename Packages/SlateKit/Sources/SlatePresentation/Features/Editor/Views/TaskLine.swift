import SwiftUI
import SlateDomain
import SlateUI

struct TaskLine: View {
    let model: TaskLineModel
    let onStatus: (NoteStatus) -> Void

    var body: some View {
        HStack(spacing: 10) {
            Menu {
                ForEach(NoteStatus.allCases, id: \.self) { status in
                    Button {
                        onStatus(status)
                    } label: {
                        if status == model.status {
                            Label(TaskStatusMapper.title(status), systemImage: "checkmark")
                        } else {
                            Text(TaskStatusMapper.title(status))
                        }
                    }
                }
            } label: {
                ModelTag(model: model.statusTag)
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .menuIndicator(.hidden)
            .fixedSize()
            .accessibilityLabel("Status: \(model.statusTag.text)")
            if let ticket = model.ticket {
                Label(ticket, systemImage: "ticket")
                    .copyOnClick(ticket, label: "Ticket")
            }
            if let branch = model.branch {
                Label(branch, systemImage: "arrow.triangle.branch")
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .copyOnClick(branch, label: "Branch")
            }
            Spacer(minLength: 0)
        }
        .font(.callout)
        .foregroundStyle(.secondary)
    }
}

#Preview("Light") {
    TaskLine(model: .preview, onStatus: { _ in })
        .padding()
        .frame(width: 480)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    TaskLine(model: .preview, onStatus: { _ in })
        .padding()
        .frame(width: 480)
        .preferredColorScheme(.dark)
}
