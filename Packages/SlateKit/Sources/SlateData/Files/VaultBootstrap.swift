import Foundation
import SlateDomain

package struct VaultBootstrap: Sendable {
    static let staleTemporaryAge: TimeInterval = 3_600
    static let welcomeTitle = "Welcome to Slate"
    static let welcomeBody = """
    Notes are plain Markdown files in your notes folder. Any text editor can open them.

    - ⌘N makes a new note in the current folder.
    - ⌘F searches the notes.
    - ⌘⇧O opens Slate in a window.

    """

    let root: URL

    package init(root: URL) {
        self.root = root
    }

    @discardableResult
    package func prepare(now: Date, timeZone: TimeZone) throws -> Bool {
        let manager = FileManager.default
        let isNew = manager.fileExists(atPath: root.appendingPathComponent(FileVaultConfigRepository.folderName).path) == false
        try manager.createDirectory(at: root, withIntermediateDirectories: true)
        for name in ["_attachments", FileTemplateRepository.folderName, FileVaultConfigRepository.folderName] {
            try manager.createDirectory(at: root.appendingPathComponent(name, isDirectory: true), withIntermediateDirectories: true)
        }
        if isNew {
            for space in SpacesConfig.defaults.spaces {
                try manager.createDirectory(at: root.appendingPathComponent(space.folder.rawValue, isDirectory: true), withIntermediateDirectories: true)
            }
            try writeWelcomeNote(now: now, timeZone: timeZone)
        }
        removeStaleTemporaryFiles(now: now)
        return isNew
    }

    private func writeWelcomeNote(now: Date, timeZone: TimeZone) throws {
        let path = VaultPath(space: SpacesConfig.defaultCaptureSpace, stem: Self.welcomeTitle)
        let url = root.appendingPathComponent(path.rawValue)
        guard FileManager.default.fileExists(atPath: url.path) == false else { return }
        let header = HeaderDefaultsPolicy.header(id: .generate(), title: Self.welcomeTitle, type: .note, now: now)
        let data = NoteCodec.encode(header: header, body: Self.welcomeBody, opaqueHeader: nil, timeZone: timeZone)
        try FileCoordination.writeCoordinated(url, data: data)
    }

    private func removeStaleTemporaryFiles(now: Date) {
        guard let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.contentModificationDateKey]) else { return }
        for case let url as URL in enumerator where url.lastPathComponent.hasSuffix(".slate-tmp") {
            let modified = (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? now
            if now.timeIntervalSince(modified) > Self.staleTemporaryAge {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }
}
