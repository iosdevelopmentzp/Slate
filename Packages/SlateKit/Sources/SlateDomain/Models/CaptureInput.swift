import Foundation

package struct CaptureInput: Hashable, Sendable {
    package enum Destination: Hashable, Sendable {
        case newNote
        case today
    }

    package var text: String
    package var space: SpaceName?
    package var type: String?
    package var destination: Destination
    package var attachments: [CaptureAttachment]

    package init(text: String, space: SpaceName? = nil, type: String? = nil, destination: Destination = .newNote, attachments: [CaptureAttachment] = []) {
        self.text = text
        self.space = space
        self.type = type
        self.destination = destination
        self.attachments = attachments
    }
}
