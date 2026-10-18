import Foundation

struct FileRowActions {
    let quickLook: () -> Void
    let open: () -> Void
    let reveal: () -> Void
    let saveToDownloads: () -> Void
    let copyPath: () -> Void
    let rename: () -> Void
    let trash: () -> Void
    let drag: () -> NSItemProvider
}

extension FileRowActions {
    static let preview = FileRowActions(
        quickLook: {},
        open: {},
        reveal: {},
        saveToDownloads: {},
        copyPath: {},
        rename: {},
        trash: {},
        drag: { NSItemProvider() }
    )
}
