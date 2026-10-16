import Foundation

enum SaveState: Equatable {
    case idle
    case saving
    case saved(Date)
    case failed(String)
}
