# ADR 0016: Slate is a window app

Status: accepted, 2026-10-19. Replaces the panel of `SPEC.md` sections 3.1 to 3.3 and `docs/PLAYBOOK.md` section 1.

## Context

Slate opened in a borderless panel under the menu bar icon. The panel closed on a click outside it and when another app became active. A file chooser (Attach file, Image, Choose…) is another window: when the owner moved to it, the panel closed. The owner wants Slate to work like a normal app, such as Terminal or a browser, and to come to the desktop where the owner is.

## Decision

1. **One normal window.** Slate has one main window with the title bar, the three columns and the remembered frame. The panel, the "Open as window" button and `⇧⌘O` are gone.
2. **Dock icon.** `LSUIElement` is `NO`. Slate shows in the Dock and in ⌘-Tab, and has its menu bar when it is active.
3. **Close hides.** The close button and `⌘W` hide the window: Slate saves the open note, takes the window off the screen and gives the focus back to the previous app. Slate keeps running. Minimize works as usual.
4. **Show from anywhere.** A click on the Dock icon, a left click on the menu bar icon, `⌥⌘N`, the menu bar menu (Show Slate, New Note), a `slate://` link and "save and open" in Quick note show the window again, with the same folder, note and caret as before.
5. **Comes to the current desktop.** The window has `moveToActiveSpace`: when Slate shows it, it moves to the desktop the owner is on, and macOS does not switch to the old desktop.
6. **Toggle.** A left click on the menu bar icon or `⌥⌘N` hides the window when it is the front window of the active app on this desktop, and shows it in every other case.
7. **Launch.** Slate opens the window at launch when the window was open when Slate quit, so a launch at login with a hidden window stays quiet.
8. **Esc** clears the search; it no longer closes anything.

Quick note keeps its own small panel: it must not take the focus of the app the owner works in.

## Consequences

- A file chooser and other windows no longer close Slate.
- The Dock shows Slate even when its window is hidden. This is the same as Terminal or Mail with no window.
- `WindowLayout` keeps the size, the list width, the sidebar and `isWindowOpen`; the panel position is gone.
- `MenuBarPanel`, `ResizeGrip`, `Surface` and the `openAsWindow` environment value are removed.

## Alternatives rejected

- Keep the panel and stop closing it while a file chooser is open: every other window (Quick Look, Settings, a screenshot) would need its own exception, and the panel still could not stay on screen while the owner works in another app.
- A window on all desktops (`canJoinAllSpaces`): the window would show on every desktop at the same time, also on desktops where the owner does not want it.
