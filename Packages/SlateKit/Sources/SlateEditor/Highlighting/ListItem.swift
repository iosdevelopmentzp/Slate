import Foundation

struct ListItem: Equatable {
    enum Marker: Equatable {
        case bullet(Character)
        case ordered(number: Int, delimiter: Character)
    }

    let indent: Int
    let marker: Marker
    let markerLength: Int
    let contentStart: Int
    let checkbox: Checkbox?

    struct Checkbox: Equatable {
        let isChecked: Bool
        let range: NSRange
    }

    var markerText: String {
        switch marker {
        case .bullet(let character): String(character)
        case .ordered(let number, let delimiter): "\(number)\(delimiter)"
        }
    }
}
