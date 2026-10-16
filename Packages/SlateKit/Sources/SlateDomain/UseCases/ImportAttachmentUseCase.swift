import Foundation

package struct ImportAttachmentUseCase: Sendable {
    let attachments: any AttachmentStore
    let clock: any Clock

    package func execute(data: Data, fileExtension: String, source: String = "paste", for note: VaultPath) async throws -> String {
        let name = try await store(source: source, fileExtension: fileExtension) { name in
            try await attachments.write(data, named: name)
        }
        return AttachmentPolicy.markdown(file: name, from: note)
    }

    package func execute(files: [URL], for note: VaultPath) async throws -> AttachmentImport {
        var result = AttachmentImport(markdown: [], linkedInPlace: [])
        for url in files {
            if let size = await attachments.externalSize(url), size > AttachmentPolicy.maxImportSize {
                result.markdown.append(AttachmentPolicy.externalMarkdown(for: url))
                result.linkedInPlace.append(url.lastPathComponent)
                continue
            }
            let original = url.lastPathComponent
            let name = try await store(source: AttachmentPolicy.source(forOriginalName: original), fileExtension: url.pathExtension) { name in
                try await attachments.copy(url, named: name)
            }
            result.markdown.append(AttachmentPolicy.markdown(file: name, originalName: original, from: note))
        }
        return result
    }

    private func store(source: String, fileExtension: String, write: (String) async throws -> Void) async throws -> String {
        let base = AttachmentPolicy.fileName(source: source, fileExtension: fileExtension, date: clock.now(), timeZone: clock.timeZone)
        var existing = try await attachments.fileNames()
        for _ in 0..<5 {
            let name = AttachmentPolicy.unique(base, among: existing)
            do {
                try await write(name)
                return name
            } catch VaultError.alreadyExists {
                existing.append(name)
            }
        }
        throw VaultError.alreadyExists(base)
    }
}
