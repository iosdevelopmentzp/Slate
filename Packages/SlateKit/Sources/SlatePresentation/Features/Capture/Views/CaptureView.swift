import SwiftUI
import SlateDomain
import SlateUI

struct CaptureView: View {
    @Environment(CaptureStore.self) private var capture
    @Environment(VaultStore.self) private var vault

    let onSave: () -> Void
    let onOpen: () -> Void
    let onCancel: () -> Void

    var body: some View {
        @Bindable var capture = capture
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                if capture.text.isEmpty {
                    Text("Type a note…")
                        .font(.system(size: 15))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .allowsHitTesting(false)
                }
                CaptureTextView(text: $capture.text, focusToken: capture.focusToken, onSave: onSave, onOpen: onOpen, onCancel: onCancel)
            }
            .frame(minHeight: 64, maxHeight: 120)
            .padding(.horizontal, 10)
            .padding(.top, 10)
            HStack(spacing: 8) {
                spaceMenu
                Spacer()
                hint("⌘⏎", "Open")
                hint("⏎", "Save")
            }
            .font(.caption)
            .padding(.horizontal, 14)
            .frame(height: 28)
            .padding(.bottom, 4)
        }
        .frame(width: 520)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Theme.border))
    }

    private var spaceName: String {
        (capture.space ?? vault.config.captureSpace).rawValue
    }

    private var spaceMenu: some View {
        Menu {
            ForEach(vault.spaces) { space in
                Button(space.folder.rawValue, systemImage: space.icon ?? "folder") {
                    capture.space = space.folder
                }
            }
        } label: {
            Label(spaceName, systemImage: "folder")
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help("Folder for the note")
    }

    private func hint(_ keys: String, _ title: String) -> some View {
        HStack(spacing: 3) {
            Text(keys).foregroundStyle(.secondary)
            Text(title).foregroundStyle(.tertiary)
        }
    }
}

#Preview("Light") {
    CaptureView(onSave: {}, onOpen: {}, onCancel: {})
        .previewEnvironment()
        .padding()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    CaptureView(onSave: {}, onOpen: {}, onCancel: {})
        .previewEnvironment()
        .padding()
        .preferredColorScheme(.dark)
}
