import SwiftUI
import SlateDomain
import SlateUI

struct BacklinksButton: View {
    let path: VaultPath

    @Environment(BacklinksStore.self) private var store
    @State private var showsList = false

    var body: some View {
        let count = store.path == path ? store.backlinks.count : 0
        Group {
            if count > 0 {
                Button {
                    showsList.toggle()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.uturn.backward")
                        Text(BacklinkRowMapper.buttonTitle(count: count))
                            .monospacedDigit()
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 7)
                    .frame(height: 22)
                    .background(Theme.hover, in: Capsule())
                }
                .buttonStyle(.plain)
                .hint(BacklinkRowMapper.hint(count: count))
                .accessibilityLabel(BacklinkRowMapper.hint(count: count))
                .popover(isPresented: $showsList, arrowEdge: .bottom) {
                    BacklinksView()
                }
            }
        }
        .task(id: path) {
            await store.show(path)
        }
    }
}

#Preview {
    BacklinksButton(path: VaultPath(rawValue: "Notes/A.md"))
        .previewEnvironment()
}
