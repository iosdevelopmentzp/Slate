---
name: panel-window
description: "How Slate's menu bar item, panel and window work: NSStatusItem plus an own NSPanel instead of MenuBarExtra, open and close rules, saved position and size, drag and resize, screen clamping, system appearance, the Surface environment value, hints overlay, global hot keys and login item. Load before changing anything in SlatePresentation/Shell (AppWindows, RootView, SidebarView, ColumnResizer, MainMenuBuilder, drag and resize), WindowLayout, hints or the status item."
---

# Panel and window

Matches the code of phase 2 (S2 to S4). Hot keys, the capture panel and the login item follow `docs/PLAYBOOK.md` sections 1 to 3.

## Why not `MenuBarExtra`

`MenuBarExtra(.window)` puts its panel back under the icon on every open and every resize, and the panel cannot be moved. Slate draws its own menu bar item and panel. The SwiftUI `App` body (`Slate/SlateApp.swift`) is `Settings { EmptyView() }`. `AppContainer` (SlateComposition, the app delegate through `@NSApplicationDelegateAdaptor`) builds the `PresentationAssembly` and `AppWindows(assembly:)` and calls `start()`. `AppWindows` owns the status item, the panel and the window and hosts `RootView().inject(assembly)`.

## Pieces

| Type | Role |
|---|---|
| `AppWindows` (Presentation/Shell) | status item button (a click toggles the panel), panel, window, click monitor, resign observer, layout observation; `package` members: `init(assembly:)`, `start()`, `showWindowOrPanel()` |
| `MenuBarPanel: NSPanel` | borderless, `canBecomeKey` true, `isFloatingPanel`, `level = .statusBar`, `hidesOnDeactivate = false`, `isReleasedWhenClosed = false`, `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]`, `animationBehavior = .none`, `isMovable = false`, clear background; `RootView` clips itself with a 12 pt rounded rectangle (`Theme.panelRadius`) |
| `Surface` (Presentation/Shared) | `.panel` or `.window`, in the environment as `\.surface`. Both show the same three columns: sidebar (`⌘0` hides it, remembered), list, note. The panel adds the "Open as window" button and the resize grip; the window has a transparent title bar and the main menu |
| `WindowLayout` (Presentation/Shared, `@Observable`) | `size` (default 1040 × 680, minimum 820 × 520), `listWidth` (260 to 420, default 320), `showsSidebar`, `panelTopLeft`, `openCount`; `panelFrame(anchor:anchorScreen:)`, `fit(window)`, `resize(to:in:)`, `reset()`; persisted through `KeyValueStore` (`window.size`, `window.panelTopLeft`) |
| `WindowDragArea` (Shell, `NSViewRepresentable`) | moves the window in `mouseDragged` (`mouseDownCanMoveWindow` false), clamps to the usable area, reports the new top-left on mouse up |
| `PanelDragArea` (Shell) | `WindowDragArea` behind the sidebar title and the list title; saves `panelTopLeft`; a double-click puts the panel back under the icon. Does nothing in the window |
| `ResizeGrip` (Shell) | drag changes `layout.size`; double-click resets to the default size |
| `ColumnResizer` (Shell) | the drag edge between the list and the note; sets `layout.listWidth`; a double-click resets it |
| `WindowFrame` (Shell, modifier) | panel: fixed `frame(width:height:)` from `layout.size`; window: `frame(minWidth:idealWidth:maxWidth:…)` |
| `HostWindowReader` (SlateUI) | gives a view its `NSWindow` |

## Open and close

- First open creates the `NSHostingController` and keeps it. Later opens only set the frame and call `makeKeyAndOrderFront`, then `layout.openCount += 1`. `RootView` runs `.task(id: layout.openCount)` to refresh `NoteListStore`.
- `NSApp.activate()` before `makeKeyAndOrderFront`, `statusItem.button?.highlight(true)` while open.
- Close on a global mouse-down monitor (`NSEvent.addGlobalMonitorForEvents`) and `NSApplication.didResignActiveNotification`. Remove the monitor on close. Opening the window closes the panel.
- Save before a surface goes away: `closePanel()`, `windowWillClose` and `windowDidResignKey` (AppWindows is the window delegate) call `assembly.flush()`. Quit is handled in `AppContainer` (`willTerminate` runs `pendingSave()` and waits up to 3 s).
- First launch: `AppContainer` shows `FirstLaunchWindow` (a normal titled window with `FirstLaunchView`) before any `AppWindows` exists, because the ports need the vault folder.
- A synthetic click from `osascript` opens the panel but does not make Slate the active app, so scripted keystrokes go to the frontmost app. UI checks with the keyboard need a person.
- Callbacks from AppKit hop to the main actor with `Task { @MainActor [weak self] in guard let self else { return } … }`. Never `MainActor.assumeIsolated`, never `DispatchQueue.main` (`docs/ARCHITECTURE.md` sections 3 and 11).

## Position and size

- The anchor is the status item button frame in screen coordinates: `x = midX - width / 2`, `y = minY - 4`. A saved `panelTopLeft` wins over the anchor.
- `panelFrame` picks the screen that holds the top-left point (else the anchor screen, else main), takes `visibleFrame` inset by 12, clamps the size to that area and writes the clamped size back, clamps the point, and returns the frame. On a small screen the panel is smaller than 980 × 680.
- `fit(window)` re-applies the frame when the layout changes (observed with `withObservationTracking`, re-armed after each change). When `panelTopLeft` becomes nil, the frame goes back to the icon.

## Window

`NSWindow` with `[.titled, .closable, .miniaturizable, .resizable]`, normal level, `isReleasedWhenClosed = false`, `contentMinSize = WindowLayout.minimumSize`, `setFrameAutosaveName(WindowLayout.windowAutosaveName)` (`"SlateMainWindow"`). `NSHostingController.sizingOptions = [.minSize]`.

## Appearance

Slate follows the system appearance. Do nothing: no `WindowAppearance`, no `.colorScheme(...)` on `RootView`, never `NSApp.appearance`. Colours come from `Theme`, which maps to system colours. Every view has a light and a dark `#Preview`.

## Hints

`HintCenter` (`@Observable`, in the environment as `\.hintCenter`; files under `SlateUI/Hint/`) holds one `Hint(id, text, frame)`. `.hint(_:)` reports its global frame, starts a task on hover (0.55 s, or 0.06 s when a hint was shown in the last 0.8 s) and shows the hint. A local event monitor for mouse down, key down and scroll hides it. `HintOverlay` sits in an `.overlay` of `RootView`. Never `.help`: the system tooltip is slow in the panel.

## Later: hot keys, capture panel, login item

- Hot keys: `KeyboardShortcuts` names in `SlateComposition/Hotkeys.swift` (`PLAYBOOK.md` section 3). The handler calls `AppWindows.showWindowOrPanel()`.
- Capture panel: a non-activating `NSPanel` copied from Verba's `FloatingPanel` (`PLAYBOOK.md` section 2). Never `NSApp.activate` for it.
- Login item: `SMAppService.mainApp.register()`; `requiresApproval` means System Settings → Login Items.

## Traps

- Alerts and sheets inside the panel are unreliable, and `docs/UX.md` forbids them. Inline confirmation only.
- The borderless panel does not show its content to the Accessibility API, so `osascript` cannot read it. A script can check that the panel is on screen with `CGWindowListCopyWindowInfo` (owner `Slate`, layer 25).
- Two menu bar icons mean two instances: `pkill -x Slate`.
