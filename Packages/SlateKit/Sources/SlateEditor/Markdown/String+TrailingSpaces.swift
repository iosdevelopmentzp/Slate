import Foundation

extension String {
    var trailingSpacesRemoved: String {
        var copy = self
        while let last = copy.last, last == " " || last == "\t" {
            copy.removeLast()
        }
        return copy
    }
}
