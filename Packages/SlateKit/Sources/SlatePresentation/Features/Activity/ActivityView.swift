import SwiftUI
import SlateDomain
import SlateUI

struct ActivityView: View {
    @Environment(ActivityLog.self) private var activity
    @Environment(Toaster.self) private var toaster

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Activity")
                    .font(.headline)
                Spacer()
                Button("Clear") { activity.clear() }
                    .controlSize(.small)
                    .disabled(activity.events.isEmpty)
            }
            if activity.events.isEmpty {
                Text("Nothing went wrong lately.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(activity.events) { event in
                            row(event)
                        }
                    }
                }
                .frame(maxHeight: 320)
            }
        }
        .padding(12)
        .frame(width: 380)
    }

    private func row(_ event: ActivityEvent) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon(for: event.outcome))
                .foregroundStyle(tint(for: event.outcome).color)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(event.title)
                        .font(.callout.weight(.medium))
                        .lineLimit(2)
                    Spacer()
                    Text(event.date.relativeDescription(to: .now))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if event.detail.isEmpty == false {
                    Text(event.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(4)
                        .textSelection(.enabled)
                }
            }
        }
        .contextMenu {
            Button("Copy", systemImage: "doc.on.doc") {
                toaster.copy("\(event.title)\n\(event.detail)", label: "Message")
            }
        }
    }

    private func icon(for outcome: ActivityEvent.Outcome) -> String {
        switch outcome {
        case .success: "checkmark.circle.fill"
        case .failure: "exclamationmark.triangle.fill"
        case .info: "info.circle.fill"
        }
    }

    private func tint(for outcome: ActivityEvent.Outcome) -> Tint {
        switch outcome {
        case .success: .green
        case .failure: .orange
        case .info: .blue
        }
    }
}

#Preview("Light") {
    ActivityView()
        .previewEnvironment()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ActivityView()
        .previewEnvironment()
        .preferredColorScheme(.dark)
}
