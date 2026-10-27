import Foundation

package struct MoveFolderUseCase: Sendable {
    let files: any VaultFileStore
    let config: any VaultConfigRepository
    let reindex: ReindexVaultUseCase

    package func execute(_ folder: FolderPath, into parent: FolderPath?) async throws -> FolderMove? {
        try await move(folder, into: parent, restoring: nil)
    }

    package func undo(_ done: FolderMove) async throws {
        let restoring = done.space.map { ($0, done.position ?? Int.max) }
        _ = try await move(done.to, into: done.from.parent, restoring: restoring)
    }

    private func move(_ folder: FolderPath, into parent: FolderPath?, restoring: (Space, Int)?) async throws -> FolderMove? {
        guard let target = FolderMovePolicy.target(of: folder, into: parent) else { return nil }
        var spaces = try await config.spaces()
        var removed: (space: Space, position: Int)?
        if folder.isSpace {
            let name = folder.space
            guard name != spaces.captureSpace else { throw VaultError.defaultFolderMove(name.rawValue) }
            if let index = spaces.spaces.firstIndex(where: { $0.folder == name }) {
                guard spaces.spaces[index].isProject == false else { throw VaultError.projectMove(name.rawValue) }
                removed = (spaces.spaces[index], index)
            }
        }
        if target.isSpace {
            guard SpaceNamePolicy.validated(target.name) != nil else { throw VaultError.invalidName(target.name) }
            guard spaces.spaces.contains(where: { StemPolicy.isSame($0.folder.rawValue, target.name) }) == false else {
                throw VaultError.alreadyExists(target.name)
            }
        } else {
            let siblings = try await files.folders().filter { $0.parent == parent }
            guard siblings.contains(where: { StemPolicy.isSame($0.name, target.name) }) == false else {
                throw VaultError.alreadyExists(target.name)
            }
        }
        try await files.moveFolder(from: folder, to: target)
        try await rewriteLinks(below: target, movedFrom: folder)
        if let removed {
            spaces.spaces.remove(at: removed.position)
            if spaces.archiveSpace == removed.space.folder { spaces.archiveSpace = spaces.captureSpace }
        }
        if target.isSpace {
            let entry = restoring.map { $0.0.renamed(to: target.space) } ?? Space(folder: target.space, icon: "folder.fill", defaultType: NoteType.defaultName)
            spaces.spaces.insert(entry, at: min(restoring?.1 ?? spaces.spaces.count, spaces.spaces.count))
        }
        if removed != nil || target.isSpace {
            try await config.saveSpaces(spaces)
        }
        _ = try await reindex.execute(.all)
        return FolderMove(from: folder, to: target, space: removed?.space, position: removed?.position)
    }

    private func rewriteLinks(below target: FolderPath, movedFrom folder: FolderPath) async throws {
        guard target.depth != folder.depth else { return }
        let notes = try await files.enumerate().map(\.path).filter { $0.isNote && target.contains($0) }
        for path in notes {
            let old = VaultPath(rawValue: folder.rawValue + path.rawValue.dropFirst(target.rawValue.count))
            let contents = try await files.read(path)
            let text = String(decoding: contents.data, as: UTF8.self)
            let rewritten = AttachmentPolicy.rewriteLinks(in: text, from: old, to: path)
            guard rewritten != text else { continue }
            _ = try await files.write(path, data: Data(rewritten.utf8), expected: contents.hash)
        }
    }
}
