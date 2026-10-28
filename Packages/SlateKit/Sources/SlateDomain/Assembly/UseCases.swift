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
    package let setProject: SetProjectUseCase
    package let createProject: CreateProjectUseCase
    package let startTask: StartTaskUseCase
    package let importFolder: ImportFolderUseCase
    package let findProject: FindProjectUseCase
    package let projectTasks: ProjectTasksUseCase
    package let findTask: FindTaskUseCase
    package let logProgress: LogProgressUseCase
    package let linkRepository: LinkRepositoryUseCase
    package let setTaskStatus: SetTaskStatusUseCase
    package let renameSpace: RenameSpaceUseCase
    package let deleteSpace: DeleteSpaceUseCase
    package let restoreSpace: RestoreSpaceUseCase
    package let createFolder: CreateFolderUseCase
    package let renameFolder: RenameFolderUseCase
    package let deleteFolder: DeleteFolderUseCase
    package let moveFolder: MoveFolderUseCase
    package let restoreFolder: RestoreFolderUseCase
    package let importAttachment: ImportAttachmentUseCase
    package let attachScreenshot: AttachScreenshotUseCase
    package let ensureDaily: EnsureDailyNoteUseCase
    package let append: AppendToNoteUseCase
    package let capture: QuickCaptureUseCase
    package let purgeTrash: PurgeTrashUseCase
    package let snapshot: SnapshotHistoryUseCase
    package let saveVersion: SaveVersionUseCase
    package let restoreVersion: RestoreVersionUseCase
    package let restoreFileVersion: RestoreFileVersionUseCase
    package let clearHistory: ClearHistoryUseCase
    package let toggleTodo: ToggleTodoUseCase
    package let runAction: RunActionUseCase
    package let openTarget: OpenTargetUseCase
    package let agentGuide: AgentGuideWriter
    package let backlinks: BacklinksUseCase

    package init(ports: Ports) {
        create = CreateNoteUseCase(files: ports.files, index: ports.index, builder: ports.builder, templates: ports.templates, config: ports.config, keyValues: ports.keyValues, clock: ports.clock)
        save = SaveNoteUseCase(files: ports.files, index: ports.index, builder: ports.builder, clock: ports.clock)
        rename = RenameNoteUseCase(files: ports.files, index: ports.index, builder: ports.builder, save: save)
        move = MoveNoteUseCase(files: ports.files, index: ports.index, builder: ports.builder)
        archive = ArchiveNoteUseCase(config: ports.config, move: move)
        duplicate = DuplicateNoteUseCase(files: ports.files, index: ports.index, builder: ports.builder, clock: ports.clock)
        updateHeader = UpdateHeaderUseCase(files: ports.files, save: save)
        trash = TrashNoteUseCase(trash: ports.trash, index: ports.index, clock: ports.clock)
        restore = RestoreNoteUseCase(trash: ports.trash, files: ports.files, index: ports.index, builder: ports.builder)
        startTask = StartTaskUseCase(files: ports.files, config: ports.config, create: create, keyValues: ports.keyValues)
        setTaskStatus = SetTaskStatusUseCase(files: ports.files, updateHeader: updateHeader)
        reindex = ReindexVaultUseCase(files: ports.files, index: ports.index, builder: ports.builder)
        createSpace = CreateSpaceUseCase(files: ports.files, config: ports.config)
        setProject = SetProjectUseCase(config: ports.config)
        createProject = CreateProjectUseCase(createSpace: createSpace, setProject: setProject)
        importFolder = ImportFolderUseCase(files: ports.files, config: ports.config, createProject: createProject, setProject: setProject, reindex: reindex)
        renameSpace = RenameSpaceUseCase(files: ports.files, config: ports.config, reindex: reindex)
        deleteSpace = DeleteSpaceUseCase(files: ports.files, config: ports.config, move: move)
        restoreSpace = RestoreSpaceUseCase(files: ports.files, config: ports.config, move: move)
        createFolder = CreateFolderUseCase(files: ports.files)
        renameFolder = RenameFolderUseCase(files: ports.files, reindex: reindex)
        deleteFolder = DeleteFolderUseCase(files: ports.files, move: move)
        moveFolder = MoveFolderUseCase(files: ports.files, config: ports.config, reindex: reindex)
        restoreFolder = RestoreFolderUseCase(files: ports.files, move: move)
        importAttachment = ImportAttachmentUseCase(attachments: ports.attachments, clock: ports.clock)
        attachScreenshot = AttachScreenshotUseCase(capture: ports.capture, attachments: ports.attachments, clock: ports.clock)
        ensureDaily = EnsureDailyNoteUseCase(files: ports.files, config: ports.config, create: create, keyValues: ports.keyValues, clock: ports.clock)
        append = AppendToNoteUseCase(files: ports.files, index: ports.index, save: save, create: create, ensureDaily: ensureDaily, clock: ports.clock)
        capture = QuickCaptureUseCase(create: create, append: append, config: ports.config, keyValues: ports.keyValues)
        purgeTrash = PurgeTrashUseCase(trash: ports.trash, keyValues: ports.keyValues, clock: ports.clock)
        snapshot = SnapshotHistoryUseCase(history: ports.history, keyValues: ports.keyValues)
        saveVersion = SaveVersionUseCase(history: ports.history, keyValues: ports.keyValues, snapshot: snapshot)
        restoreVersion = RestoreVersionUseCase(history: ports.history, files: ports.files, save: save)
        restoreFileVersion = RestoreFileVersionUseCase(history: ports.history, files: ports.files)
        clearHistory = ClearHistoryUseCase(history: ports.history)
        toggleTodo = ToggleTodoUseCase(files: ports.files, index: ports.index, save: save)
        runAction = RunActionUseCase(runner: ports.actions, append: append)
        openTarget = OpenTargetUseCase(index: ports.index, create: create)
        agentGuide = AgentGuideWriter(files: ports.files)
        backlinks = BacklinksUseCase(files: ports.files, index: ports.index)
        findProject = FindProjectUseCase(config: ports.config, repositories: ports.repositories)
        projectTasks = ProjectTasksUseCase(files: ports.files, index: ports.index)
        findTask = FindTaskUseCase(config: ports.config, projectTasks: projectTasks)
        logProgress = LogProgressUseCase(append: append, clock: ports.clock)
        linkRepository = LinkRepositoryUseCase(config: ports.config, repositories: ports.repositories, setProject: setProject)
    }
}
