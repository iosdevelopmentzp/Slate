import Foundation

enum SettingsPage: String, CaseIterable, Identifiable {
    case general
    case shortcuts

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .general: "General"
        case .shortcuts: "Shortcuts"
        }
    }

    var icon: String {
        switch self {
        case .general: "gearshape"
        case .shortcuts: "keyboard"
        }
    }
}
