import Foundation

package struct ActionResult: Hashable, Sendable {
    package var output: String
    package var exitCode: Int32
    package var appended: NoteDocument?

    package init(output: String, exitCode: Int32, appended: NoteDocument? = nil) {
        self.output = output
        self.exitCode = exitCode
        self.appended = appended
    }

    package var succeeded: Bool {
        exitCode == 0
    }
}
