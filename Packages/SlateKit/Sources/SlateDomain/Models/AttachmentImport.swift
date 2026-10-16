import Foundation

package struct AttachmentImport: Hashable, Sendable {
    package var markdown: [String]
    package var linkedInPlace: [String]

    package init(markdown: [String], linkedInPlace: [String]) {
        self.markdown = markdown
        self.linkedInPlace = linkedInPlace
    }

    package var text: String {
        markdown.joined(separator: "\n")
    }
}
