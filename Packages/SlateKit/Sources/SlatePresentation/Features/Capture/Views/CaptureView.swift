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
            .frame(minHeight: 64, maxHeight: 140)
            .padding(.horizontal, 12)
            .padding(.top, 12)
            HStack(spacing: 8) {
                folderMenu
                Spacer()
                Button(action: onSave) {
                    HStack(spacing: 4) {
                        Text("⏎").foregroundStyle(.secondary)
                        Text("Save")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 10)
                    .frame(height: 24)
                    .background(Theme.hover, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(capture.canSave == false)
                .hint("Enter saves. ⌘Enter saves and opens the note.")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .frame(width: 520)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.quickNoteRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.quickNoteRadius, style: .continuous).strokeBorder(Theme.border.opacity(0.5)))
    }

    private var folder: Space? {
        vault.config.space(capture.space ?? vault.config.captureSpace)
    }

    private var folderMenu: some View {
        Menu {
            ForEach(vault.spaces) { space in
                Button(space.folder.rawValue, systemImage: FolderRowMapper.icon(for: space)) {
                    capture.space = space.folder
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: folder.map(FolderRowMapper.icon(for:)) ?? "folder.fill")
                    .foregroundStyle(FolderTint.tint(folder?.color ?? .blue).color)
                Text((capture.space ?? vault.config.captureSpace).rawValue)
                    .foregroundStyle(.primary)
            }
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 10)
            .frame(height: 24)
            .background(Theme.hover, in: Capsule())
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .fixedSize()
        .hint("Folder for the note")
        .accessibilityLabel("Folder for the note")
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
