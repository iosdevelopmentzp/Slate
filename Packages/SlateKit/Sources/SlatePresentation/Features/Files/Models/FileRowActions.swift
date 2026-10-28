import Foundation

struct FileRowActions {
    let select: () -> Void
    let quickLook: () -> Void
    let open: () -> Void
    let reveal: () -> Void
    let saveToDownloads: () -> Void
    let copyPath: () -> Void
    let rename: () -> Void
    let trash: () -> Void
    let versions: () -> Void
    let drag: () -> NSItemProvider
}

extension FileRowActions {
    static let preview = FileRowActions(
        select: {},
        quickLook: {},
        open: {},
        reveal: {},
        saveToDownloads: {},
        copyPath: {},
        rename: {},
        trash: {},
        versions: {},
        drag: { NSItemProvider() }
    )
}
