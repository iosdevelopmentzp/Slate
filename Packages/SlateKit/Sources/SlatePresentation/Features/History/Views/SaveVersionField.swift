import SwiftUI
import SlateUI

struct SaveVersionField: View {
    let onSave: (String) async -> Bool

    @State private var name = ""
    @State private var isSaving = false

    var body: some View {
        HStack(spacing: 6) {
            TextField("Name this version", text: $name)
                .textFieldStyle(.roundedBorder)
                .onSubmit(save)
                .accessibilityLabel("Version name")
            Button("Save Version", action: save)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
        }
        .controlSize(.small)
    }

    private func save() {
        guard isSaving == false else { return }
        isSaving = true
        Task {
            if await onSave(name) { name = "" }
            isSaving = false
        }
    }
}

#Preview("Light") {
    SaveVersionField { _ in true }
        .padding()
        .frame(width: 320)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    SaveVersionField { _ in true }
        .padding()
        .frame(width: 320)
        .preferredColorScheme(.dark)
}
