import SwiftUI
import SlateDomain
import SlateUI

struct UpdateButton: View {
    @Environment(UpdateStore.self) private var store
    @State private var showsDetails = false

    var body: some View {
        if store.state != .idle {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Button {
                    guard store.isRunning == false else { return }
                    showsDetails = true
                } label: {
                    label(now: context.date)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .popover(isPresented: $showsDetails, arrowEdge: .trailing) {
                UpdateDetails(state: store.state, log: store.log) {
                    showsDetails = false
                    Task { await store.update() }
                }
                .task { await store.loadLog() }
            }
        }
    }

    private func label(now: Date) -> some View {
        HStack(spacing: 8) {
            if store.isRunning {
                ProgressView().controlSize(.small)
            } else {
                Image(systemName: icon)
            }
            Text(UpdateBadgeMapper.title(for: store.state, now: now) ?? "")
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .font(.callout.weight(.medium))
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .frame(height: 30)
        .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: Theme.pillRadius, style: .continuous))
        .contentShape(Rectangle())
        .hint(hint)
        .accessibilityLabel(UpdateBadgeMapper.title(for: store.state, now: now) ?? "Update")
    }

    private var icon: String {
        if case .failed = store.state { return "exclamationmark.triangle.fill" }
        return "arrow.down.circle.fill"
    }

    private var tint: Color {
        if case .failed = store.state { return Tint.orange.color }
        return Theme.selection
    }

    private var hint: String {
        switch store.state {
        case .available: "See the changes and update Slate"
        case .running: "Slate opens again when the update is installed"
        case .failed: "See what went wrong"
        case .idle: ""
        }
    }
}

#Preview {
    UpdateButton()
        .frame(width: 240)
        .previewEnvironment()
}
