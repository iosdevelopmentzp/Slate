import Foundation

final class CodeLanguageChoice: NSObject {
    let location: Int
    let fence: String?

    init(location: Int, fence: String?) {
        self.location = location
        self.fence = fence
    }
}
