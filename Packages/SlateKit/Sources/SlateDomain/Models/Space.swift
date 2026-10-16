import Foundation

package struct Space: Identifiable, Hashable, Sendable {
    package let folder: SpaceName
    package var icon: String?
    package var defaultType: String?
    package var noteCount: Int

    package var id: SpaceName {
        folder
    }

    package init(folder: SpaceName, icon: String? = nil, defaultType: String? = nil, noteCount: Int = 0) {
        self.folder = folder
        self.icon = icon
        self.defaultType = defaultType
        self.noteCount = noteCount
    }
}
