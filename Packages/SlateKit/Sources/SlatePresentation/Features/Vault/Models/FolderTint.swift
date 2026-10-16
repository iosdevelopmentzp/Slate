import Foundation
import SlateDomain
import SlateUI

enum FolderTint {

    static func tint(_ color: SpaceColor) -> Tint {
        switch color {
        case .red: .red
        case .orange: .orange
        case .yellow: .yellow
        case .green: .green
        case .teal: .teal
        case .blue: .blue
        case .purple: .purple
        case .pink: .pink
        }
    }

    static func title(_ color: SpaceColor) -> String {
        switch color {
        case .red: "Red"
        case .orange: "Orange"
        case .yellow: "Yellow"
        case .green: "Green"
        case .teal: "Teal"
        case .blue: "Blue"
        case .purple: "Purple"
        case .pink: "Pink"
        }
    }
}
