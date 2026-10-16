import Foundation
import Observation

@MainActor
@Observable
package final class EditorCommands {
    package internal(set) var state = EditorStyleState()
    @ObservationIgnored weak var controller: RichTextController?

    package init() {}

    package func perform(_ command: EditorCommand) {
        controller?.perform(command)
    }

    package func flush() {
        controller?.flush()
    }

    package func focus() {
        controller?.focus()
    }
}
