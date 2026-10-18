import AppKit
import SwiftUI
import SlateDomain
import SlateUI

struct FolderMenu: View {
    let model: FolderRowModel
    let canMoveUp: Bool
    let canMoveDown: Bool
    let onNewInside: () -> Void
    let onRename: () -> Void
    let onColor: (SpaceColor) -> Void
    let onIcon: (String) -> Void
    let onMove: (Int) -> Void
    let onProject: (Bool) -> Void
    let onNewTask: () -> Void
    let onLinkRepository: () -> Void
    let onDelete: () -> Void

    var body: some View {
        if model.isProject {
            Button("New Task", systemImage: "checkmark.circle", action: onNewTask)
        }
        Button("New folder inside", systemImage: "folder.badge.plus", action: onNewInside)
        Button("Rename", systemImage: "pencil", action: onRename)
        if model.isSpace {
            spaceItems
        }
        Divider()
        Button("Delete folder", systemImage: "trash", role: .destructive, action: onDelete)
            .disabled(model.canDelete == false)
    }

    @ViewBuilder
    private var spaceItems: some View {
        Menu("Colour") {
            ForEach(SpaceColor.allCases, id: \.self) { color in
                Button {
                    onColor(color)
                } label: {
                    Label {
                        Text(FolderTint.title(color))
                    } icon: {
                        ColorDot.image(NSColor(FolderTint.tint(color).color))
                    }
                }
            }
        }
        Menu("Icon") {
            ForEach(FolderIcon.all, id: \.self) { icon in
                Button(icon.title, systemImage: icon.symbol) {
                    onIcon(icon.symbol)
                }
            }
        }
        Divider()
        Button("Move up", systemImage: "arrow.up") { onMove(-1) }
            .disabled(canMoveUp == false)
        Button("Move down", systemImage: "arrow.down") { onMove(1) }
            .disabled(canMoveDown == false)
        Divider()
        if model.isProject {
            Button(model.repository == nil ? "Link Repository…" : "Change Repository…", systemImage: "link", action: onLinkRepository)
            Button("Make a Folder", systemImage: "folder") { onProject(false) }
        } else {
            Button("Make a Project", systemImage: SetProjectUseCase.projectIcon) { onProject(true) }
        }
    }
}
