import Foundation

final class ImageMenuChoice: NSObject {
    let path: String
    let action: AttachmentAction

    init(path: String, action: AttachmentAction) {
        self.path = path
        self.action = action
    }
}
