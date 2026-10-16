import Foundation

enum SettingsPage: String, CaseIterable, Identifiable {
    case general
    case folder
    case shortcuts
    case links

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .general: "General"
        case .folder: "Notes folder"
        case .shortcuts: "Shortcuts"
        case .links: "Links"
        }
    }

    var icon: String {
        switch self {
        case .general: "gearshape"
        case .folder: "folder"
        case .shortcuts: "keyboard"
        case .links: "link"
        }
    }
}
