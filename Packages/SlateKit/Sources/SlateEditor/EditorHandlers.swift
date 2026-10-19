import Foundation

package struct EditorHandlers {
    package var didEndEditing: () -> Void
    package var resolveImage: (String) -> URL?
    package var openLink: (EditorLink) -> Void
    package var attachment: (String, AttachmentAction) -> Void
    package var pasteImage: (Data, String) -> Void
    package var pasteFiles: ([URL]) -> Void
    package var requestScreenshot: (ScreenshotKind) -> Void
    package var notice: (String) -> Void
    package var noteNames: () async -> [String]

    package init(
        didEndEditing: @escaping () -> Void = {},
        resolveImage: @escaping (String) -> URL? = { _ in nil },
        openLink: @escaping (EditorLink) -> Void = { _ in },
        attachment: @escaping (String, AttachmentAction) -> Void = { _, _ in },
        pasteImage: @escaping (Data, String) -> Void = { _, _ in },
        pasteFiles: @escaping ([URL]) -> Void = { _ in },
        requestScreenshot: @escaping (ScreenshotKind) -> Void = { _ in },
        notice: @escaping (String) -> Void = { _ in },
        noteNames: @escaping () async -> [String] = { [] }
    ) {
        self.didEndEditing = didEndEditing
        self.resolveImage = resolveImage
        self.openLink = openLink
        self.attachment = attachment
        self.pasteImage = pasteImage
        self.pasteFiles = pasteFiles
        self.requestScreenshot = requestScreenshot
        self.notice = notice
        self.noteNames = noteNames
    }
}
