import Foundation

struct PasteboardSnapshot {
    var image: (data: Data, fileExtension: String)?
    var fileURLs: [URL] = []
    var string: String?
    var html: String?
}
