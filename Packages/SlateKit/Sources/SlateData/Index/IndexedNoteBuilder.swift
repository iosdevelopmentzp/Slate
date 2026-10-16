import Foundation
import Markdown

struct IndexedNoteBuilder {
    func headingCount(in body: String) -> Int {
        var walker = HeadingCounter()
        walker.visit(Document(parsing: body))
        return walker.count
    }
}

private struct HeadingCounter: MarkupWalker {
    var count = 0

    mutating func visitHeading(_ heading: Heading) {
        count += 1
        descendInto(heading)
    }
}
