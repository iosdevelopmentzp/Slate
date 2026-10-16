import Foundation
import SlateDomain

enum PaletteItem: Identifiable {
    case note(SearchHit)
    case command(PaletteCommand)

    var id: String {
        switch self {
        case .note(let hit): "note:\(hit.id.rawValue)"
        case .command(let command): "command:\(command.id)"
        }
    }
}
