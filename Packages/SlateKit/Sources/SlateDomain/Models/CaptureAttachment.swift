import Foundation

package enum CaptureAttachment: Hashable, Sendable {
    case image(Data, fileExtension: String)
    case file(URL)

    package var name: String {
        switch self {
        case .image(_, let fileExtension): "Image.\(fileExtension)"
        case .file(let url): url.lastPathComponent
        }
    }

    package var isImage: Bool {
        switch self {
        case .image: true
        case .file(let url): AttachmentPolicy.isImage(url.lastPathComponent)
        }
    }
}
