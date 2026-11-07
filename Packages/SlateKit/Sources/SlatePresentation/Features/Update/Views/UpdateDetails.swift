import SwiftUI
import SlateDomain
import SlateUI

struct UpdateDetails: View {
    let state: UpdateStore.State
    let log: String
    let onUpdate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            switch state {
            case .available(let commits):
                Text("New in Slate")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(UpdateBadgeMapper.lines(of: commits), id: \.self) { line in
                        Label(line, systemImage: "circle.fill")
                            .labelStyle(BulletLabelStyle())
                            .font(.callout)
                    }
                }
                Text("Slate builds the new version first and closes only to install it.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Update Now", action: onUpdate)
                    .buttonStyle(AccentButtonStyle())
            case .failed(let message):
                Text("Update failed")
                    .font(.headline)
                Text(message)
                    .font(.callout)
                ScrollView {
                    Text(UpdateBadgeMapper.logTail(log).isEmpty ? "No log." : UpdateBadgeMapper.logTail(log))
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 180)
                .background(Theme.base, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                Button("Try Again", action: onUpdate)
                    .buttonStyle(AccentButtonStyle())
            case .idle, .running:
                EmptyView()
            }
        }
        .padding(14)
        .frame(width: 360, alignment: .leading)
    }
}

private struct BulletLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            configuration.icon
                .font(.system(size: 4))
                .foregroundStyle(.secondary)
            configuration.title
        }
    }
}

#Preview("Available") {
    UpdateDetails(state: .available([UpdateCommit(hash: "a1b2c3d", subject: "feat(editor): callouts"), UpdateCommit(hash: "b2c3d4e", subject: "fix: the list keeps its place")]), log: "", onUpdate: {})
}

#Preview("Failed") {
    UpdateDetails(state: .failed("The build failed."), log: "error: something went wrong", onUpdate: {})
}
