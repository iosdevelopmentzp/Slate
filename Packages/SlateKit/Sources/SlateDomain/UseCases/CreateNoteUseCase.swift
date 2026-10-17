import Foundation

package struct CreateNoteUseCase: Sendable {
    let files: any VaultFileStore
    let index: any SearchIndex
    let builder: any IndexedNoteBuilding
    let templates: any TemplateRepository
    let config: any VaultConfigRepository
    let keyValues: any KeyValueStore
    let clock: any Clock

    package func execute(_ draft: NoteDraft) async throws -> CreatedNote {
        let spaces = try await config.spaces()
        let types = try await config.types()
        let requested = (draft.folder?.space ?? draft.space).flatMap { spaces.space($0) }
        let type = HeaderDefaultsPolicy.type(named: draft.type, space: requested, among: types)
        let space = HeaderDefaultsPolicy.space(for: type, requested: requested?.folder, config: spaces)
        let typed = draft.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        var ticket = draft.ticket
        var bareTitle = typed
        if type.fields.contains("ticket") {
            let split = TitlePolicy.split(typed, ticketPattern: TrackerSettings.load(from: keyValues).ticketPattern)
            if let found = split.ticket, ticket == nil || StemPolicy.isSame(found, ticket ?? "") {
                ticket = found
                bareTitle = split.title
            }
        }
        let rendered = ticket == nil ? typed : TitlePolicy.render(type.titlePattern, ticket: ticket, title: bareTitle)
        let title = rendered.isEmpty ? (ticket ?? StemPolicy.untitled) : rendered
        let folder = draft.folder.flatMap { $0.space == space ? $0 : nil } ?? FolderPath(space: space)
        let stems = try await NoteStems.stems(inFolder: folder.rawValue, files: files)
        let path = VaultPath(folder: folder, stem: StemPolicy.unique(StemPolicy.stem(forTitle: title), among: stems))
        let now = clock.now()
        var header = HeaderDefaultsPolicy.header(id: .generate(), title: title, type: type, now: now)
        if type.fields.contains("ticket") {
            header.ticket = ticket
            header.branch = SlugPolicy.renderBranch(pattern: type.branchPattern, ticket: ticket, title: bareTitle)
        }
        let body: TemplateRenderer.Rendered
        if let text = draft.body {
            body = TemplateRenderer.Rendered(text: text, caret: (text as NSString).length)
        } else {
            let template = try await templates.body(for: draft.template ?? type.name)
            body = TemplateRenderer.render(template, values: TemplateRenderer.values(title: title, header: header, now: now, timeZone: clock.timeZone))
        }
        let prefix = draft.bodyPrefix ?? ""
        let text = prefix + body.text
        let data = NoteCodec.encode(header: header, body: text, opaqueHeader: nil, timeZone: clock.timeZone)
        let hash = try await files.create(path, data: data)
        let meta = try await files.meta(path) ?? FileMeta(path: path, created: now, modified: now, size: data.count)
        let document = NoteDocument(path: path, header: header, body: text, hash: hash, meta: meta)
        try await index.upsert(builder.build(document))
        return CreatedNote(document: document, caret: (prefix as NSString).length + body.caret)
    }
}
