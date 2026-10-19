import Foundation

enum LinkAction: Int, CaseIterable {
    case open
    case edit
    case copy
    case remove

    var title: String {
        switch self {
        case .open: "Open Link"
        case .edit: "Edit Link…"
        case .copy: "Copy Link Address"
        case .remove: "Remove Link"
        }
    }

    var symbol: String {
        switch self {
        case .open: "arrow.up.right.square"
        case .edit: "pencil"
        case .copy: "doc.on.doc"
        case .remove: "xmark"
        }
    }
}
