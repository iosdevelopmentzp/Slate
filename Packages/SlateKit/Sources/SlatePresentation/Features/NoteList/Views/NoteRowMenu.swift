import SwiftUI
import SlateDomain

struct NoteRowMenu: View {
    let isPinned: Bool
    let actions: NoteRowActions

    var body: some View {
        Button(isPinned ? "Unpin" : "Pin", systemImage: isPinned ? "pin.slash" : "pin", action: actions.pin)
        if actions.moveTargets.isEmpty == false {
            Menu("Move to", systemImage: "folder") {
                ForEach(actions.moveTargets) { target in
                    Button(target.title, systemImage: target.icon) {
                        actions.move(target.id)
                    }
                }
            }
        }
        Button("Duplicate", systemImage: "plus.square.on.square", action: actions.duplicate)
        Divider()
        Button("Move to Trash", systemImage: "trash", role: .destructive, action: actions.requestTrash)
    }
}
