import SwiftUI

package struct ModelTag: View {
    package let model: TagModel

    package init(model: TagModel) {
        self.model = model
    }

    package var body: some View {
        Tag(model.text, tint: model.tint.color, systemImage: model.systemImage)
            .hint(model.hint)
    }
}

#Preview {
    HStack {
        ModelTag(model: TagModel("Done", tint: .green, systemImage: "checkmark"))
        ModelTag(model: TagModel("3 to do", tint: .orange, systemImage: "checklist", hint: "Open checkboxes"))
        ModelTag(model: TagModel("Pinned", systemImage: "pin.fill"))
    }
    .padding()
}
