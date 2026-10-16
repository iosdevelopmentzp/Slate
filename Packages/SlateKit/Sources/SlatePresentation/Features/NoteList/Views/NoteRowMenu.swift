import SwiftUI
import SlateDomain

struct NoteRowMenu: View {
    let isPinned: Bool
    let actions: NoteRowActions

    var body: some View {
        Button(isPinned ? "Unpin" : "Pin", systemImage: isPinned ? "pin.slash" : "pin", action: actions.pin)
        if actions.moveTargets.isEmpty == false {
            Menu("Move to", systemImage: "folder") {
                ForEach(actions.moveTargets) { space in
                    Button(space.folder.rawValue, systemImage: space.icon ?? "folder") {
                        actions.move(space.folder)
                    }
                }
            }
        }
        Button("Duplicate", systemImage: "plus.square.on.square", action: actions.duplicate)
        Divider()
        Button("Move to Trash", systemImage: "trash", role: .destructive, action: actions.requestTrash)
    }
}
