import Foundation

struct TextEdit: Equatable {
    let range: NSRange
    let replacement: String
    let selection: NSRange
}
