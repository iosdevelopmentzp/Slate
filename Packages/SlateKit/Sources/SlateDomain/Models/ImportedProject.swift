import Foundation

package struct ImportedProject: Hashable, Sendable {
    package let space: SpaceName
    package let report: FolderImport

    package init(space: SpaceName, report: FolderImport) {
        self.space = space
        self.report = report
    }
}
