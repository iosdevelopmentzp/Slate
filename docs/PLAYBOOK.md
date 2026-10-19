# Technical playbook: verified solutions and traps

Read the section for a topic before writing code for it. Items marked **verified** were used in `../DevHub` or `../Verba` and work on macOS 26. Items marked **verify first** are the expected approach with a named check; run the check in a small throwaway file before building on it, and write the result into `docs/STATUS.md`.

---

## 1. Menu bar item and panel — verified (DevHub)

> Slate no longer uses the panel (ADR 0016). The notes below stay for the Quick note panel and for history. The main window: `MainWindow` (`NSWindow`, `collectionBehavior` with `.moveToActiveSpace`), `windowShouldClose` returns `false` and hides the window, `applicationShouldHandleReopen` shows it, `LSUIElement = NO`. To bring a visible window from another desktop, `orderOut` it first, then `makeKeyAndOrderFront`.
>
> **Activate with `NSApp.activate(ignoringOtherApps: true)`, not `NSApp.activate()`.** From a status item click the system refuses the plain `activate()` (cooperative activation, macOS 14+): `NSApp.isActive` stays `false` and the window opens behind the active app. The Dock click works either way, because the Dock activates the app itself. `activate(ignoringOtherApps: true)` gives no deprecation warning with the macOS 26 SDK. `NSWorkspace.openApplication` on the own bundle also activates, but it calls `applicationShouldHandleReopen`, which calls `showWindow` again: an endless loop. An `orderFrontRegardless()` or a deferred `activate()` does not help. Checked on 2026-10-19 with a trace file and a `CGEvent` click on the icon.

Copy `AppWindows`, `MenuBarPanel`, `WindowLayout`, the drag and resize views and `HintOverlay` from `../DevHub/Packages/DevHubKit/Sources/DevHubPresentation/Shell/` and rename.

- **Do not use `MenuBarExtra(.window)`.** It puts the panel back under the icon on every open and resize and cannot be moved. Use `NSStatusItem` plus an own borderless `NSPanel` subclass: `canBecomeKey` true, `isFloatingPanel`, `level = .statusBar`, `hidesOnDeactivate = false`, `isReleasedWhenClosed = false`, `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]`, `animationBehavior = .none`, `isMovable = false`, clear background with an own rounded clip and shadow. The SwiftUI `App` body is `Settings { EmptyView() }` only.
- **Open at once.** Create the hosting controller on the first open and keep it; later opens only set the frame and call `makeKeyAndOrderFront`. An `openCount` drives `.task(id:)` in `RootView` for refreshes.
- **Close rules.** A global mouse-down monitor (`NSEvent.addGlobalMonitorForEvents`) and `NSApplication.didResignActiveNotification` close the panel. Remove the monitor on close. Save the open note before the close.
- **Position.** `WindowLayout` keeps size and top-left in `UserDefaults`, clamps the frame 12 points inside `visibleFrame` of the screen that holds the top-left point, shrinks when the screen is smaller. Move by an `NSView` that handles `mouseDown` / `mouseDragged` and calls `setFrameOrigin` (`mouseDownCanMoveWindow` false).
- **Windows.** `NSWindow` with `setFrameAutosaveName`, the same root view with a `Surface` environment value; `NSHostingController.sizingOptions = [.minSize]` so the window resizes by its edges.
- **Appearance.** Slate follows the system appearance: do nothing. Never set `NSApp.appearance`: the menu bar icon label turns black on a dark menu bar.
- **Launch at login:** `SMAppService.mainApp.register()`; status `requiresApproval` means System Settings → Login Items; show the path in the activity log.
- **Ad-hoc signing.** Each rebuild changes the binary; macOS may ask for a permission again (Screen Recording for screenshots). Keep the bundle ID stable and install to `/Applications` for daily use.

## 2. Capture panel that does not steal focus — verified (Verba), built in M4 (`CapturePanel`, `CaptureTextView`)

Copy `FloatingPanel` and the rules in `../Verba/.claude/rules/ui-panel.md`.

- `NSPanel` with `styleMask: [.nonactivatingPanel, .borderless]`, `level = .floating`, `hidesOnDeactivate = false`, `becomesKeyOnlyIfNeeded = true`, `canBecomeKey` true, `canBecomeMain` false. Show with `orderFrontRegardless()` then `makeKey()`. **Never call `NSApp.activate`** for the capture panel; the source app stays active and gets the paste back when the user returns.
- Esc, a click outside (global monitor) and Enter close it. Keep the draft text in memory for the next open after Esc.
- Opening the main panel from the capture panel (`⌘Enter`) is the one case that activates the app.
- The text field is an `NSTextView` in a scroll view sized to the content, not a SwiftUI `TextEditor`: focus on first responder is reliable in a non-activating panel only with AppKit.

## 3. Global hotkeys — verified (Verba)

- `KeyboardShortcuts` (sindresorhus). Every `KeyboardShortcuts.Name` is in one file, `SlatePresentation/Shared/KeyboardShortcuts+Slate.swift`, with defaults: `togglePanel` ⌥⌘N, `capture` ⌃⌥Space, `today` ⌥⌘T. `AppWindows.start()` registers the handlers (`onKeyUp`, each handler hops with `Task { @MainActor … }`); `stop()` calls `removeAllHandlers()`. The recorder view `KeyboardShortcuts.Recorder` is in Settings → Shortcuts. (M4: the names moved from Composition because the recorder needs them in Presentation.)
- No Accessibility permission is needed. A conflict with a system shortcut shows in the recorder; the Doctor lists the current values.
- Fallback with no dependency: Carbon `RegisterEventHotKey` as in DevHub's `GlobalHotKey`; no recorder then.

## 4. File coordination and atomic writes — verified (M1)

Expected approach (standard AppKit, used by document-based apps):

- Reads: `NSFileCoordinator(filePresenter: nil).coordinate(readingItemAt: url, options: [], error: &error) { url in … }` on a background task. Writes: `options: .forReplacing`, write to `.<name>.slate-tmp` in the same folder, then `FileManager.default.replaceItemAt(url, withItemAt: tmp)` (default options keep the creation date). Moves: `coordinate(writingItemAt: from, options: .forMoving, writingItemAt: to, options: .forReplacing)` and call `coordinator.item(at: from, didMoveTo: to)` inside the block.
- **Never nest coordinated calls** for the same URL: it deadlocks. One coordinated block per file operation; the use case orders operations, the store never coordinates.
- Coordinated calls block the calling thread: never on the main actor. Port methods are `async` and run in the nonisolated Data module.
- Do not register an `NSFilePresenter` per note: it does not scale to thousands of files. FSEvents (section 5) is the change source.
- Check (M1), done: `FileVaultStoreIntegrationTests` writes 40 versions while `sh` touches the file 200 times; every read is a whole version and the last write wins. `FileVaultStoreTests` covers the conflict path, the kept creation date and that no `.slate-tmp` file stays behind.
- The store is an `actor`, so coordinated calls never run on the main actor. With `NonisolatedNonsendingByDefault`, a plain `nonisolated async` method runs on the caller's actor: long work in a struct needs `@concurrent` (`ReindexVaultUseCase.execute`).
- A folder rename that changes only the case (`Reading` → `reading`) fails as one move on a case-insensitive disk. Move through a temporary hidden name (`FileVaultStore.moveFolder`).

## 5. FSEvents watcher — verified (M1)

- `FSEventStreamCreate` on the vault root with `kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagNoDefer`, latency `0.3`, since `kFSEventStreamEventIdSinceNow`. `FSEventStreamSetDispatchQueue` to a serial queue, `FSEventStreamStart`. Stop, invalidate and release on deinit.
- Paths arrive as strings; standardise before comparing (`URL(fileURLWithPath:).standardizedFileURL.resolvingSymlinksInPath()`): the vault may be reported under `/private/var` or with a different case.
- `kFSEventStreamEventFlagMustScanSubDirs` or `kFSEventStreamEventFlagRootChanged`: run a full scan.
- Events come for our own writes, for `.slate-tmp` files and for `.icloud` placeholders. `ChangeCoalescer` groups paths for 300 ms, drops ignored names, drops own writes (same path, same hash on disk within two seconds).
- Check (M1), done in `FSEventsVaultWatcherIntegrationTests`: an edit gives `.paths([path])`, a rename gives both paths, a delete gives the path, a new folder gives `.rescan`, and an own write gives nothing. `VaultChange` has no kind: the reindex reads the disk for each path.
- Trap: `URL.resolvingSymlinksInPath()` removes `/private` only when the file exists. A deleted or renamed-away file then keeps `/private/var/…` and no longer matches the root. `ChangeCoalescer` resolves the root once and removes the `/private` prefix from event paths by hand.
- Trap: the event for the root folder itself and the events for folders made just before the stream started arrive in the first batch. The root path is ignored; a folder event means `.rescan`, and `.rescan` wins over the paths of the same batch.
- `String.write(atomically:)` from other tools writes `<name>.sb-…` temporary files next to the note; they are not `.md` and are ignored.
- Cancelling the task that iterates an `AsyncStream` finishes the stream and stops the FSEvents session. Tests use one consumer for the whole test.

## 6. Vault inside iCloud Drive (F3, P2) — verify first

Only for a vault the owner places inside a synced folder. The default vault is a local folder.

- Detect iCloud Drive: the vault path is under `~/Library/Mobile Documents/com~apple~CloudDocs/`. `FileManager.default.ubiquityIdentityToken` says whether iCloud is signed in. The app has no iCloud entitlement; it works on the folder like any other folder.
- A not-downloaded file appears in the folder listing as `.Name.md.icloud` (a small plist). Treat it as the note `Name.md` in state "in cloud". To download: `FileManager.default.startDownloadingUbiquitousItem(at: realURL)` where `realURL` is the path without the dot prefix and the `.icloud` suffix. **Check (M5):** this call may need the entitlement; if it throws, fall back to `brctl download <path>` through `ShellRunner` (Apple's command line tool for iCloud Drive, present on every Mac) and report which one works in `STATUS.md`.
- Resource keys for status: `ubiquitousItemDownloadingStatusKey` (`.current`, `.downloaded`, `.notDownloaded`), `ubiquitousItemIsUploadingKey`, `ubiquitousItemHasUnresolvedConflictsKey`, `ubiquitousItemDownloadingErrorKey`. Read them in `UbiquityStatusProvider` on a background task; cache for the list; refresh on `vaultChanged`.
- Conflicts: `NSFileVersion.unresolvedConflictVersionsOfItem(at:)` returns the other versions with `modificationDate` and `localizedNameOfSavingComputer`. Keep current: set `isResolved = true` on each other version, then `NSFileVersion.removeOtherVersionsOfItem(at:)`. Keep other: read `version.url` bytes, write them as the current content through the normal save, then resolve as above. Keep both: write the other version as `<Title> (conflict YYYY-MM-DD HHmm).md`, then resolve.
- iCloud "touches" files (same bytes, new modification date) after a sync: the index must compare the hash before re-parsing, and `updated` in the header, not the file date, is what the list shows.
- Never put `.git` inside the iCloud folder (section 8).

## 7. `ShellRunner` — verified (DevHub)

Copy `ShellRunner`, `ShellResult`, `LineBatcher`, `CommandFormatter` from `../DevHub/Packages/DevHubKit/Sources/DevHubData/Shell/`.

- One `actor ShellRunner` with `run(executable, arguments, cwd, environment) -> ShellResult` and `stream(...)`. Launch through `/usr/bin/env <executable>`; prepend `/opt/homebrew/bin` and `/usr/local/bin` to `PATH`.
- **Deadlock trap.** Blocking pipe reads on the Swift concurrency pool hang when many commands run at once. Read stdout and stderr on a dedicated concurrent `DispatchQueue`, then `waitUntilExit`.
- Every run is reported to `CommandRecording` (start, output, finish, duration, exit code) so it shows in the Activity view. Commands that could print a secret are classified `secret` and record no output (none in Slate v1; the Jira token travels in a header, never on a command line).
- Cancellation: `withTaskCancellationHandler` whose `onCancel` calls `process.terminate()`.

## 8. Git history outside the vault — verified (M5)

- Repository location: `~/Library/Application Support/Slate/<vault-id>/history.git`. Every git command gets the environment `GIT_DIR=<that path>` and `GIT_WORK_TREE=<vault>` and runs with `cwd = vault`. The vault never gets a `.git` folder or file.
- Create: `git init` with both variables set, then write `<GIT_DIR>/info/exclude` with `.DS_Store`, `*.icloud`, `*.slate-tmp`, `.trash/`, `.obsidian/`. Set `core.autocrlf=false`, `core.quotepath=false`, `gc.auto=0` (run `git gc` only from the Doctor, by hand).
- Identity per command: `-c user.name=Slate -c user.email=slate@localhost`. No global config is read or written.
- Snapshot: `git add -A`, then `git diff --cached --quiet`; exit code 1 means there are changes, then `git commit -q -m "snapshot: <n> files"` where `n` comes from `git diff --cached --numstat | wc -l`. Exit code 0 from `diff --cached --quiet` means nothing to commit: do not create empty commits.
- Per-file history: `git log --format=%H%x09%ct%x09%s --follow -- "<relative path>"`. Content at a version: `git show <hash>:"<relative path>"` (path relative to the work tree, forward slashes). Restore goes through `SaveNoteUseCase`, never through `git checkout`, so the index and the open editor update.
- Push: `git push -q <remote> HEAD:refs/heads/main` only when Settings has a remote; a failure is one activity line and a retry at the next snapshot, not an alert.
- Serialise: one git command at a time per repository (the actor does this). The first snapshot of a large vault can take seconds: background, with an activity line.
- Check (M5), done: `GitHistoryRepositoryIntegrationTests` makes a repository with `GIT_DIR` and `GIT_WORK_TREE`, takes two snapshots, reads the per-file log and an old version, and pushes to a bare remote. No `.git` appears in the work tree; a snapshot without changes makes no commit.
- Trap (M5): `git diff --cached --quiet` exits 1 when there are changes, and `git log` exits 128 in a repository without commits. `ShellRunner.run(…, tolerating:)` marks these exit codes, so they do not show as failures in Activity.
- `GitHistoryRepository` is an actor, so one git command runs at a time. `GIT_TERMINAL_PROMPT=0` keeps a push from waiting for a password.

## 9. TextKit 2 editor — verified in the M1.5 spike (ADR 0005 amendment)

- Create the view with `NSTextView(usingTextLayoutManager: true)` inside an own `NSScrollView`. **Never touch `textView.layoutManager`** (the TextKit 1 property): one access switches the view to TextKit 1 for good, silently. `check-layers.sh` forbids the token in `SlateEditor`.
- Turn off `isAutomaticQuoteSubstitutionEnabled`, `isAutomaticDashSubstitutionEnabled`, `isAutomaticTextReplacementEnabled`, `isAutomaticDataDetectionEnabled`, `isAutomaticLinkDetectionEnabled` (links are styled by the editor itself), `usesFontPanel`. Keep spell checking on; `isGrammarCheckingEnabled` off. `allowsUndo = true`.
- Programmatic edits go through `shouldChangeText(in:replacementString:)` → `textStorage.replaceCharacters` → `didChangeText()`, or `insertText(_:replacementRange:)`, so undo keeps working. Wrap multi-step edits in `textContentStorage.performEditingTransaction { }`.
- **Display-only styling**: implement `NSTextContentStorageDelegate.textContentStorage(_:textParagraphWith:)`. Return an `NSTextParagraph` with an attributed string of **exactly the same length** as the source paragraph; only attributes change. Changing the length breaks the mapping between display and source. This is why checkbox glyphs are drawn over the `[ ]` characters (section below), not substituted.
- Fence state: `FenceTracker` keeps, per line, `isInsideFence` and the language. `NSTextStorageDelegate.textStorage(_:didProcessEditing:range:changeInLength:)` updates the lines in the edited range and continues down until a line's state equals the cached state. After a fence change, call `textLayoutManager.invalidateLayout(for:)` on the range from the edit to that line.
- **Custom drawing**: implement `NSTextLayoutManagerDelegate.textLayoutManager(_:textLayoutFragmentFor:in:)` and return a subclass of `NSTextLayoutFragment` for lines that need it: `CheckboxLayoutFragment` draws the box glyph over the `[ ]` characters (which are drawn in the clear colour by the paragraph styler); `ImageLayoutFragment` draws the image below the line. Checked (M1.5): the paragraph styler sets `paragraphSpacing` on the image line to the image height plus 8; this grows the fragment's frame, and the fragment extends `renderingSurfaceBounds` into that space and draws there. Slate uses one fragment class, `MarkdownLayoutFragment`, with a `LineDecoration` read from a custom attribute of the display paragraph.
- Trap (M1.5): `NSTextLayoutFragment` is not main-actor isolated. In the MainActor module the subclass is `nonisolated final class`, and the values it reads are `nonisolated` types.
- Trap (M1.5): `layoutFragmentFrame` is only as wide as the text of the line. Full-width backgrounds use `textLayoutManager.textContainer.size.width`.
- Lines below an edit whose fence state changed: `FenceTracker` updates in `textStorage(_:willProcessEditing:…)`; the extra range is regenerated from `textDidChange` with `textContentStorage.performEditingTransaction { textStorage.edited(.editedAttributes, range:, changeInLength: 0) }`.
- Hit testing for a checkbox or an image click: `textLayoutManager.textLayoutFragment(for: point)` → the fragment's `textElement?.elementRange` → the line → the command.
- Copy button on a code block: an `NSView` overlay positioned from the fence's first fragment frame (`layoutFragmentFrame`), updated on layout through `NSTextViewportLayoutControllerDelegate` or `textLayoutManager.enumerateTextLayoutFragments`. Keep it simple: show the button for the fence that contains the mouse position, recompute on mouse move.
- Line height for prose: `NSMutableParagraphStyle.lineHeightMultiple = 1.35` in the display paragraph. Code lines use `1.2`.
- Performance: style only in the delegate (lazy, per paragraph as the viewport needs it). Never apply attributes to the whole storage after an edit. Measure with the 5,000-line fixture: an edit must restyle under 16 ms.
- The open-source `MarkdownEngine` package (`swift-markdown-engine`, Apache 2.0, pre-1.0) was measured in the M1.5 spike and rejected: 79 ms per keystroke on the 5,000-line fixture against 2.2 ms for the own core, a wikilink storage form that conflicts with `[[Stem|alias]]`, and a highlighter that runs JavaScript (ADR 0005 amendment).

### Rich text editor (S3, ADR 0008)

- The S3 editor no longer uses the display-only styling of the content storage delegate above. The storage holds the real fonts, because the text has no marks; the `slate.*` attributes stay the single truth and the styler derives the look from them. The bullets above about `[ ]` glyphs and `FenceTracker` describe the M2 editor, which is gone.
- Trap (S3): `replace` calls `textView.shouldChangeText`, which calls the delegate's `shouldChangeTextIn`. Set the "editing internally" flag before that call, or a redirect inside the delegate calls `replace` again and the stack overflows.
- Trap (S3): an `NSTextAttachment` subclass with `allowsTextAttachmentView = false` must also set its `image` property. Overriding `image(for:attributes:location:textContainer:)` alone reserves the space but draws nothing.
- Trap (S3): `layoutFragmentFrame.minX` is the paragraph indent. A background or a bar drawn from the left edge of the text column subtracts it.
- Trap (S3): in a test there is no event loop, so the `UndoManager` puts every change into one group. Tests set `groupsByEvent = false` and open a group per step.
- Writing Markdown for 130,000 characters takes about 100 ms in a debug build. The controller writes long notes 250 ms after the last key, and flushes before a save.

### Tables as attachment views (S6, ADR 0009)

- Trap (S6): TextKit 2 hosts an attachment view only through a provider class registered with `NSTextAttachment.registerViewProviderClass(_:forFileType:)` for a file type the system knows, and only for an attachment made with `init(data:ofType:)` with non-empty data. Overriding `viewProvider(for:location:textContainer:)` gives a provider whose `loadView` is never called. Slate registers `TableViewProvider` for `public.tab-separated-values-text`.
- Trap (S6): an attachment subclass that overrides `attachmentBounds(for:…)` gets no view either. The size comes from the provider: set `tracksTextAttachmentViewBounds = true` in its `init` and override the provider's `attachmentBounds`.
- Trap (S6): with a file type the attachment draws the file icon under the view. Override `image(for:attributes:location:textContainer:)` and return an empty image.
- Trap (S6): TextKit 2 loads the view later on the main queue. A Swift Testing test on the main actor never sees it; the editor tests add the view to the text view by hand (`EditorHarness.layout()`), and `TableBlockView` waits for `viewDidMoveToWindow` before it takes the focus. The agent checked the real hosting once with a throwaway XCTest that runs `RunLoop.main`; Swift Testing is the rule for committed tests.
- Trap (S6): never call `mouseDown(with:)` of a text view from the `mouseDown` of another view. `NSTextView` runs its own mouse tracking loop and does not return in that case; the app hangs. Set the selection with `characterIndexForInsertion(at:)` instead.
- When the row height changes, `invalidateLayout(for:)` on the attachment range resizes the view; the focus of the cell editor stays (checked with an XCTest in a window). `viewWillMove(toWindow:)` keeps the selection in case TextKit moves the view.

## 10. GRDB and FTS5 — verified (M3)

- `DatabasePool(path:configuration:)` with `configuration.busyMode = .timeout(2)` and WAL (the pool's default). One pool per vault, owned by `GRDBSearchIndex`.
- Schema through `DatabaseMigrator` with a migration `v1` that creates the tables of `STORAGE-FORMAT.md` section 9. The FTS table: `try db.create(virtualTable: "notes_fts", using: FTS5()) { t in t.tokenizer = .unicode61(diacritics: .remove, tokenchars: ["_", "-"]); t.column("note_id").notIndexed(); t.column("title"); t.column("body"); t.column("tags"); t.column("ticket") }`. The system SQLite on macOS has FTS5.
- Upsert per note in one write transaction: delete from every table by `note_id`, insert again. Batch the full scan 200 notes per transaction.
- Query: `SELECT note_id, bm25(notes_fts, 0.0, 10.0, 1.0, 4.0, 8.0) AS rank, snippet(notes_fts, 2, '', '', '…', 12) AS snippet FROM notes_fts WHERE notes_fts MATCH ? ORDER BY rank LIMIT ?`, then join with `notes` in Swift or in SQL for the filters. The weights follow the column order `note_id, title, body, tags, ticket`.
- **Never pass user text to `MATCH` directly.** `FTSMatchBuilder` turns each word into `"word"*` (prefix match, inner quotes doubled) and each quoted phrase into `"phrase"`, joined with spaces. A word that is only punctuation is dropped. An empty result string means "no FTS part": use the filters only.
- `ABC-123` stays one token because `-` is a token character; `ABC` alone matches by prefix.
- Filters become `WHERE` clauses on `notes` (`type`, `status`, `space`, `ticket`, `pinned`, `in_conflict`, `has_*`), `EXISTS` on `tags` and `todos`. `-tag:x` is `NOT EXISTS`.
- Check (M3), done: `GRDBSearchIndexTests.hostileInputNeverThrows` covers `"`, `'`, `(`, `:`, `-`, `*`, `NEAR(` and `AND OR NOT`. `IndexPerformanceTests` over `Scripts/generate-vault.sh` with 10,000 notes (debug build): full scan 11 s, unchanged scan 0.4 s, a two-word search 28 ms median. The generated notes use about 50 words, so every two-word query matches almost every note; that is the worst case for ranking.
- Verified (M3): the schema is raw SQL in migration `v1`, so the tokenizer string is exactly the one of `STORAGE-FORMAT.md` section 9. The FTS row uses the `rowid` of the `notes` row; joins and deletes go through `rowid`. The weights are set once as the table's `rank` (`INSERT INTO notes_fts(notes_fts, rank) VALUES('rank', 'bm25(0.0, 10.0, 1.0, 4.0, 8.0)')`) and the query uses `ORDER BY rank`.
- Trap (M3): `String.replacingOccurrences(of:options: .regularExpression)` compiles the pattern on every call. `PreviewPolicy` did that ten times per line and took most of the scan time. Keep compiled `NSRegularExpression` values in `static let` and check a cheap `contains` first.
- Trap (M3): a full scan that reads and parses one file after the other took 27 s. `ReindexVaultUseCase` now reads and builds 200 files at a time in a task group; `FileVaultStore.read` is `nonisolated` so the reads run in parallel.
- Trap (M3): a stored `mtime` as unix seconds in a `REAL` does not round-trip a `Date` exactly. `IndexedFileState.matches` allows 1 ms.

## 11. Screenshots — built in M2, the permission check is open

- Region: `screencapture -i -x -t png "<path>"`. Window: `screencapture -i -W -o -x -t png "<path>"` (`-W` starts in window mode, `-o` no shadow, `-x` no sound). The path is the final attachment path from `FileAttachmentStore`.
- Success is **"the file exists and is larger than zero bytes"**. Esc during the capture leaves no file; do not rely on the exit code.
- Hide the panel before the command (`orderOut`) and show it again after, so the panel is not in the picture. The window stays.
- **Screen Recording permission.** macOS attributes the permission to Slate (the parent of `screencapture`). The first use shows the system prompt; the user enables Slate in System Settings → Privacy & Security → Screen Recording and restarts the app. After an ad-hoc rebuild the permission may be asked again. The activity log line names the setting path. **Check (M2):** the prompt appears once, the second capture works without a prompt; after a rebuild note what happens in `STATUS.md`.
- Run through `ShellRunner` with a 120 s timeout (the user may take time to select the region).

## 12. URL scheme, Services menu, Info.plist — verified pattern (standard AppKit)

- URL scheme: `CFBundleURLTypes` with `CFBundleURLSchemes = [slate]` and `CFBundleURLName`. Handled in `AppContainer.application(_:open:)`; `AppContainer` is the delegate through `@NSApplicationDelegateAdaptor` in `SlateApp`. Register the app once by launching it (or `lsregister -f <app>`); `open "slate://capture"` in a terminal is the test.
- Verified (M6): an Apple Event handler for `kAEGetURL` set from `AppContainer` is replaced by SwiftUI when the app finishes launching, and the URL that starts the app is lost. The delegate's `application(_:open:)` gets both the cold-start URL and later ones. URLs that arrive before the windows exist wait in a queue.
- Services: `NSServices` array in `Info.plist` with one entry: `NSMenuItem = { default = "Add to Slate" }`, `NSMessage = addToSlate`, `NSPortName = Slate`, `NSSendTypes = [public.utf8-plain-text]`. Set `NSApp.servicesProvider` in `AppContainer` when it launches; the method is `@objc func addToSlate(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString>)`. After installing a new build run `/System/Library/CoreServices/pbs -update` (or log out and in) so the Services menu lists it. The app must be in `/Applications` or have been launched once.
- `GENERATE_INFOPLIST_FILE = YES` cannot express `NSServices` or URL types. Verified (M6): with `INFOPLIST_FILE = Config/Slate-Info.plist` and `GENERATE_INFOPLIST_FILE` still on, Xcode merges the generated keys (`LSUIElement`, bundle id, version) into that file. The file lives outside `Slate/`, because `Slate/` is a synchronized folder and would copy it as a resource.
- Both entry points parse into `URLCommand` / a capture input, validate, and call a use case. No shell, no file path from a URL is ever executed or written outside the vault.

## 13. Build scripts and smoke check — verified (DevHub)

- `Scripts/build.sh`: `check-layers.sh`, then `xcodebuild -project Slate.xcodeproj -scheme Slate -configuration <c> -destination 'platform=macOS' -derivedDataPath DerivedData -quiet build`. With `-quiet` any output besides `layers: ok` and the app path is a warning or an error and must be fixed.
- Smoke check after a build: start the binary inside the `.app`, wait 3 s, `kill -0` confirms it is alive, kill it. Two menu bar icons mean two instances: `pkill -x Slate`.
- `Scripts/test.sh`: `cd Packages/SlateKit && swift test -q`, one summary line, `--skip integration` filters suites whose name ends in `IntegrationTests`.
- "resource fork, Finder information, or similar detritus not allowed": `xattr -cr Slate/`.
- Previews in package files render in Xcode through the `Slate` scheme.
- Never `cp` a new binary over a signed binary that already exists. macOS keeps the code signature of the old file, so the new one is killed at start (exit 137, `Killed: 9`), and `codesign -v` still says it is valid. Copy to a new file and `mv` it over the old one. `install.sh` does this for `~/.local/bin/slate`.
- Do not start a test copy of Slate with `--args -vault.path <folder>` to keep the real notes safe. The copy shares the settings of the installed Slate (`local.slate.app`), and `AppContainer` saves the folder it opened back to `vault.path`. The installed Slate and `slate mcp` then open the test folder. If it happens, restore it with `defaults write local.slate.app vault.path <real folder>` and restart Slate.

## 14. Performance measurement

- `Scripts/generate-vault.sh <folder> <count>` writes notes with a header, 3 to 40 paragraphs, tags, 0 to 5 todos, one code fence in a third of them, one image link in a tenth (a shared 200 KB PNG), spread over the six default spaces. Use it for M3 and M2 budgets.
- Time the index with `ContinuousClock` around the full scan and one incremental update; print the numbers in the Doctor.
- Typing latency: Instruments, "Animation Hitches" and "Time Profiler" with the 5,000-line fixture open; the `SlateEditorTests` performance test guards regressions.
- Panel open: `os_signpost` from the status item click to the first `onAppear` of the list.
