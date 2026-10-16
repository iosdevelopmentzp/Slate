import Foundation

package struct UseCases: Sendable {
    package let create: CreateNoteUseCase
    package let save: SaveNoteUseCase
    package let rename: RenameNoteUseCase
    package let move: MoveNoteUseCase
    package let archive: ArchiveNoteUseCase
    package let duplicate: DuplicateNoteUseCase
    package let updateHeader: UpdateHeaderUseCase
    package let trash: TrashNoteUseCase
    package let restore: RestoreNoteUseCase
    package let reindex: ReindexVaultUseCase
    package let createSpace: CreateSpaceUseCase
    package let renameSpace: RenameSpaceUseCase
    package let importAttachment: ImportAttachmentUseCase
    package let attachScreenshot: AttachScreenshotUseCase

    package init(ports: Ports) {
        create = CreateNoteUseCase(files: ports.files, index: ports.index, builder: ports.builder, templates: ports.templates, config: ports.config, clock: ports.clock)
        save = SaveNoteUseCase(files: ports.files, index: ports.index, builder: ports.builder, clock: ports.clock)
        rename = RenameNoteUseCase(files: ports.files, index: ports.index, builder: ports.builder, save: save)
        move = MoveNoteUseCase(files: ports.files, index: ports.index, builder: ports.builder)
        archive = ArchiveNoteUseCase(config: ports.config, move: move)
        duplicate = DuplicateNoteUseCase(files: ports.files, index: ports.index, builder: ports.builder, clock: ports.clock)
        updateHeader = UpdateHeaderUseCase(files: ports.files, save: save)
        trash = TrashNoteUseCase(trash: ports.trash, index: ports.index, clock: ports.clock)
        restore = RestoreNoteUseCase(trash: ports.trash, files: ports.files, index: ports.index, builder: ports.builder)
        reindex = ReindexVaultUseCase(files: ports.files, index: ports.index, builder: ports.builder)
        createSpace = CreateSpaceUseCase(files: ports.files, config: ports.config)
        renameSpace = RenameSpaceUseCase(files: ports.files, config: ports.config, reindex: reindex)
        importAttachment = ImportAttachmentUseCase(attachments: ports.attachments, clock: ports.clock)
        attachScreenshot = AttachScreenshotUseCase(capture: ports.capture, attachments: ports.attachments, clock: ports.clock)
    }
}
