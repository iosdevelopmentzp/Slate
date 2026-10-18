import SwiftUI
import SlateUI

struct ClearHistoryRow: View {
    @Environment(VersionsStore.self) private var versions

    var body: some View {
        if versions.confirmingClear == .everything {
            InlineConfirmation(
                "Remove every older version of every note and file? Only the notes as they are now stay. A backup remote gets the short history at the next backup.",
                confirmTitle: "Clear History",
                confirmRole: .destructive,
                onCancel: { versions.cancelClear() },
                onConfirm: { Task { await versions.confirmClear() } }
            )
        } else {
            HStack {
                Text("Older versions take space in the history.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if versions.isClearing {
                    ProgressView().controlSize(.small)
                }
                Button("Clear History…", role: .destructive) {
                    versions.requestClear(.everything)
                }
                .disabled(versions.isClearing)
            }
        }
    }
}

#Preview("Light") {
    Form { ClearHistoryRow() }
        .formStyle(.grouped)
        .previewEnvironment()
        .frame(width: 480)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    Form { ClearHistoryRow() }
        .formStyle(.grouped)
        .previewEnvironment()
        .frame(width: 480)
        .preferredColorScheme(.dark)
}
