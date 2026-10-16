import Foundation

package struct SpacesConfig: Hashable, Sendable {
    package static let defaultSpace = SpaceName(rawValue: "Notes")
    package static let defaultDailySpace = SpaceName(rawValue: "Daily")

    package var spaces: [Space]
    package var captureSpace: SpaceName
    package var archiveSpace: SpaceName
    package var dailySpace: SpaceName

    package init(
        spaces: [Space],
        captureSpace: SpaceName = SpacesConfig.defaultSpace,
        archiveSpace: SpaceName = SpacesConfig.defaultSpace,
        dailySpace: SpaceName = SpacesConfig.defaultDailySpace
    ) {
        self.spaces = spaces
        self.captureSpace = captureSpace
        self.archiveSpace = archiveSpace
        self.dailySpace = dailySpace
    }

    package func space(_ name: SpaceName) -> Space? {
        spaces.first { $0.folder == name }
    }

    package static let defaults = SpacesConfig(spaces: [
        Space(folder: SpacesConfig.defaultSpace, icon: "folder.fill", defaultType: "note"),
    ])

    package static let sixFolders = SpacesConfig(
        spaces: [
            Space(folder: SpaceName(rawValue: "Inbox"), icon: "tray", defaultType: "note"),
            Space(folder: SpaceName(rawValue: "Tasks"), icon: "checkmark.circle", defaultType: "task"),
            Space(folder: SpaceName(rawValue: "Notes"), icon: "note.text", defaultType: "note"),
            Space(folder: SpaceName(rawValue: "Daily"), icon: "calendar", defaultType: "daily"),
            Space(folder: SpaceName(rawValue: "Snippets"), icon: "chevron.left.forwardslash.chevron.right", defaultType: "snippet"),
            Space(folder: SpaceName(rawValue: "Archive"), icon: "archivebox", defaultType: "note"),
        ],
        captureSpace: SpaceName(rawValue: "Inbox"),
        archiveSpace: SpaceName(rawValue: "Archive")
    )
}
