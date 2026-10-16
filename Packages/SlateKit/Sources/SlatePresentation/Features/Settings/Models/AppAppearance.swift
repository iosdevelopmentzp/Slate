import Foundation

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .system: "Match the system"
        case .light: "Light"
        case .dark: "Dark"
        }
    }
}
