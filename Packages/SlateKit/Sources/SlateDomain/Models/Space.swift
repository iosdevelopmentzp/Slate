import Foundation

package struct Space: Identifiable, Hashable, Sendable {
    package let folder: SpaceName
    package var icon: String?
    package var color: SpaceColor
    package var defaultType: String?
    package var noteCount: Int

    package var id: SpaceName {
        folder
    }

    package init(folder: SpaceName, icon: String? = nil, color: SpaceColor = .blue, defaultType: String? = nil, noteCount: Int = 0) {
        self.folder = folder
        self.icon = icon
        self.color = color
        self.defaultType = defaultType
        self.noteCount = noteCount
    }

    package func renamed(to folder: SpaceName) -> Space {
        Space(folder: folder, icon: icon, color: color, defaultType: defaultType, noteCount: noteCount)
    }
}
