import Foundation

struct CodeToken: Equatable {
    let range: NSRange
    let kind: CodeTokenKind
}
