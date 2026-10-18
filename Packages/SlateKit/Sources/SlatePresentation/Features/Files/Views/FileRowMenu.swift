import SwiftUI

struct FileRowMenu: View {
    let actions: FileRowActions

    var body: some View {
        Button("Quick Look", systemImage: "eye", action: actions.quickLook)
        Button("Open", systemImage: "arrow.up.forward.app", action: actions.open)
        Button("Show in Finder", systemImage: "folder", action: actions.reveal)
        Button("Save to Downloads", systemImage: "arrow.down.to.line", action: actions.saveToDownloads)
        Button("Copy Path", systemImage: "doc.on.doc", action: actions.copyPath)
        Divider()
        Button("Rename", systemImage: "pencil", action: actions.rename)
        Button("Move to Trash", systemImage: "trash", role: .destructive, action: actions.trash)
    }
}
