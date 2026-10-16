import Foundation

package struct EnsureDailyNoteUseCase: Sendable {
    let files: any VaultFileStore
    let config: any VaultConfigRepository
    let create: CreateNoteUseCase
    let keyValues: any KeyValueStore
    let clock: any Clock

    package func execute(stem requested: String? = nil) async throws -> DailyNote {
        let settings = DailySettings.load(from: keyValues)
        let carryOver = settings.carriesOver
        let spaces = try await config.spaces()
        let stem = requested ?? DailyPolicy.stem(for: clock.now(), timeZone: clock.timeZone)
        let path = VaultPath(space: spaces.dailySpace, stem: stem)
        if try await files.meta(path) != nil {
            let document = try NoteCodec.decode(try await files.read(path))
            return DailyNote(document: document, wasCreated: false, caret: (document.body as NSString).length)
        }
        var prefix: String?
        if carryOver, requested == nil {
            let names = try await files.fileNames(inFolder: spaces.dailySpace.rawValue)
            let stems = names.filter { $0.hasSuffix(".\(VaultPath.noteExtension)") }.map { String($0.dropLast(VaultPath.noteExtension.count + 1)) }
            if let previous = DailyPolicy.previousStem(before: stem, among: stems) {
                let document = try NoteCodec.decode(try await files.read(VaultPath(space: spaces.dailySpace, stem: previous)))
                let items = DailyPolicy.carryOver(from: document.body)
                if items.isEmpty == false {
                    prefix = DailyPolicy.carriedBlock(items)
                }
            }
        }
        let created = try await create.execute(NoteDraft(title: stem, type: NoteType.daily.name, space: spaces.dailySpace, bodyPrefix: prefix, template: settings.template))
        return DailyNote(document: created.document, wasCreated: true, caret: created.caret)
    }
}
