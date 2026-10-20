import SwiftUI
import SlateUI

struct BacklinksView: View {
    @Environment(BacklinksStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(BacklinkRowMapper.hint(count: store.backlinks.count))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.top, 4)
            ScrollView {
                VStack(spacing: 2) {
                    ForEach(store.backlinks.map(BacklinkRowMapper.model)) { model in
                        BacklinkRow(model: model) { store.open(model.id) }
                    }
                }
            }
            .frame(maxHeight: 360)
        }
        .padding(8)
        .frame(width: 380)
    }
}

#Preview {
    BacklinksView()
        .previewEnvironment()
}
