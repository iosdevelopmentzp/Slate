import Foundation

struct LineState: Equatable {
    var start: Int
    var length: Int
    var base: LineKind
    var delimiter: FenceDelimiter?
    var kind: LineKind
    var openFence: FenceDelimiter?

    var range: NSRange { NSRange(location: start, length: length) }
}
