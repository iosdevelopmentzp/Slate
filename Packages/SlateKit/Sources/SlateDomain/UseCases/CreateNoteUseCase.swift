import Foundation

package struct CreateNoteUseCase: Sendable {
    let files: any VaultFileStore
    let index: any SearchIndex
    let builder: any IndexedNoteBuilding
    let templates: any TemplateRepository
    let config: any VaultConfigRepository
    let clock: any Clock

    package func execute(_ draft: NoteDraft) async throws -> CreatedNote {
        let spaces = try await config.spaces()
        let types = try await config.types()
        let requested = draft.space.flatMap { spaces.space($0) }
        let type = HeaderDefaultsPolicy.type(named: draft.type, space: requested, among: types)
        let space = HeaderDefaultsPolicy.space(for: type, requested: requested?.folder, config: spaces)
        let typed = draft.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let title = typed.isEmpty ? StemPolicy.untitled : typed
        let stems = try await NoteStems.stems(inFolder: space.rawValue, files: files)
        let path = VaultPath(space: space, stem: StemPolicy.unique(StemPolicy.stem(forTitle: title), among: stems))
        let now = clock.now()
        let header = HeaderDefaultsPolicy.header(id: .generate(), title: title, type: type, now: now)
        let template = try await templates.body(for: type.name)
        let rendered = TemplateRenderer.render(template, values: TemplateRenderer.values(title: title, header: header, now: now, timeZone: clock.timeZone))
        let data = NoteCodec.encode(header: header, body: rendered.text, opaqueHeader: nil, timeZone: clock.timeZone)
        let hash = try await files.create(path, data: data)
        let meta = try await files.meta(path) ?? FileMeta(path: path, created: now, modified: now, size: data.count)
        let document = NoteDocument(path: path, header: header, body: rendered.text, hash: hash, meta: meta)
        try await index.upsert(builder.build(document))
        return CreatedNote(document: document, caret: rendered.caret)
    }
}
