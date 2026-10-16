---
name: ui-components
description: "Reference for Slate's shared SwiftUI building blocks (RowContainer, InlineConfirmation, ListState, ListMessage, ToolbarBar, ListSectionHeader, LinkButtonStyle, FieldLabel, Tag, ModelTag, TagModel, IconTile, IconButton, OverflowMenu, PanelCard, SectionHeader, SearchField, StatusDot, ActionBar, FlowLayout, hints, copy on click), the SlateUI module rules (package access, package var body, copyToPasteboard), the formatters, Tint, the row model and mapper pattern, spacing and colour rules. Load before building or changing any UI in Slate."
---
> Copied from DevHub at bootstrap. The tables match `SlateUI` since M0; some examples further down still name DevHub features (worktrees, simulators). Read those as patterns.


# UI Components

All shared blocks live in the `SlateUI` module (`Packages/SlateKit/Sources/SlateUI/`), one type per file;
formatters in `Formatters/`, hints in `Hint/`. Check this list before writing a new view element. A new shared block
goes into `SlateUI` with a `#Preview` and into this table. Rules: `.claude/rules/presentation.md`,
`docs/ARCHITECTURE.md` section 6.

## The SlateUI module

- SlateUI depends on nothing in the package: SwiftUI, AppKit, Foundation, Observation only. MainActor is the
  module default. It never imports `SlateDomain`; a component takes plain values (`String`, `URL`, `Color`, `Tint`).
- Presentation uses the components from another module, so each one is `package`: the type, an explicit
  `package init`, `package var body` (or `package func body(content:)` for a modifier), `package static` tokens,
  `package` extension members (`.hint`, `.copyOnClick`, `relativeDescription`, `Tint.color`).
- Every Presentation file that uses a component or an extension member has `import SlateUI`
  (`MemberImportVisibility`).
- `FolderPicker.chooseFolder(directory:prompt:message:)` takes its start folder and texts. It runs the system open
  panel; use it only for "Choose…" in the first launch window and in Settings.
- Tests for formatters, `TagModel` and `Tint` live in `Tests/SlateUITests/`. Views have no tests.

```swift
package struct IconTile: View {
    package let systemImage: String
    package let tint: Color
    package let size: CGFloat

    package init(systemImage: String, tint: Color = .accentColor, size: CGFloat = 30) { … }

    package var body: some View { … }
}
```

## Row model and mapper

A list screen builds row models; a row renders one. No colour, icon, text, hint or enabled flag is chosen inside a
view.

```
SlatePresentation/Features/<Name>/Models/<Row>Model.swift    struct <Row>Model: Identifiable, Equatable { … static let preview }
SlatePresentation/Features/<Name>/Models/<Row>Mapper.swift   enum <Row>Mapper { static func model(for:…) -> <Row>Model }
SlatePresentation/Features/<Name>/Views/<Row>.swift          struct <Row>: View { let model: <Row>Model; let onX: () -> Void … }
```

- The model holds display strings, SF Symbol names, `Tint` values, `[TagModel]` lists, flags (`canDelete`,
  `isHighlighted`), warning texts. No `Color`, no SwiftUI import.
- The mapper is pure: domain values, `SlateDomain/Policies/` and the formatters in, model out. Sorting and grouping
  live in a mapper or the store, never in `body`.
- The screen reads its store, `ProjectSession`, `AppActions` and the lookups it needs, filters with
  `session.matchesSearch`, maps, and passes each row its model plus closures for store actions. A row reads `Toaster` and `AppActions` at
  most; its `@State` is confirmation or editing input only.
- `#Preview { <Row>(model: .preview, onX: {}) }` for every row; `.previewEnvironment()` for every screen.

## Layout blocks

| Component | Signature | Use for |
|---|---|---|
| `RowContainer` | `RowContainer(verticalPadding: 8, isHighlighted: false, highlight: Color.accentColor.opacity(0.08)) { isHovered in … }` | Every list row: padding 14 / 7–8, hover background `Theme.hover`, highlight for a selected or current row, `contentShape`. The closure gets `isHovered` for the action opacity |
| `InlineConfirmation` | `InlineConfirmation("Delete worktree X?", confirmTitle: "Delete", confirmRole: .destructive, layout: .line, systemImage: "exclamationmark.triangle.fill", tint: .red, titleFont: .caption, onCancel: {}, onConfirm: {}) { details } extra: { toggles }` | The in-row confirmation block. `layout: .stacked` for warning lines and toggles (worktree delete), `.line` for one sentence. `tint: .purple` for Clean Finished, `.orange` for rebase |
| `ListState` | `ListState(failure: ListMessage?, isLoading: Bool, loadingTitle: "Reading worktrees…", empty: ListMessage?, noResultsFor: session.searchText) { list }` | The loading / error / empty / no-results triad of a screen. `ListMessage.failure("Cannot read worktrees", description: error) { retry }` for the error |
| `ListMessage` | `ListMessage("No worktrees", systemImage: "arrow.triangle.branch", description: "…", actionTitle: "Fetch") { … }` | Title, icon, text and an optional button for `ListState` |
| `ToolbarBar` | `ToolbarBar(verticalPadding: 8, controlSize: .small) { HStack { … } }` | The strip above a list: padding 14 / 8, `Theme.base` background |
| `ListSectionHeader` | `ListSectionHeader("Finished", systemImage: "checkmark.seal.fill", iconTint: .purple, detail: "3", topPadding: 10, bottomPadding: 2) { trailing }` | Section title inside a list (caption, semibold); `SectionHeader` is the uppercase card-screen variant |
| `PanelCard` | `PanelCard { VStack { … } }` | Rounded white surface with 12 padding, full width |
| `SectionHeader` | `SectionHeader("Recent") { Button("Clear") {} }` | Uppercase caption title with an optional trailing control (Home) |
| `FieldLabel` | `FieldLabel("Device ID")` | Caption label above a field in a panel |
| `FlowLayout` | `FlowLayout(spacing: 6, lineSpacing: 4) { tags }` | Tags or short facts that wrap instead of being cut |
| `ActionBar` | `ActionBar(items: [ActionItem("Push", systemImage: "arrow.up", hint: "git push", priority: 6, isDisabled: false) { … }])` | A row of labelled buttons that never truncates: low-priority buttons drop to icons first (`ActionBarLayout` + `ActionBarFit`) |
| `HoverActions` | `HoverActions(isVisible: isHovered, count: 3, spacing: 2) { IconButton(…) … }` | Hover buttons of a row, built only on hover; keeps their space when hidden |
| `RemovableChip` | `RemovableChip("into dev", systemImage: "arrow.triangle.branch", removeHint: "Remove this filter") { … }` | An active filter above a list; a click removes it. Chips go into `FlowLayout` |

## Small blocks

| Component | Signature | Use for |
|---|---|---|
| `Tag` | `Tag("clean", tint: .green, systemImage: "checkmark")` | Status capsule, `.fixedSize()` by itself |
| `ModelTag` / `TagModel` | `ModelTag(model: TagModel("clean", tint: .green, systemImage: "checkmark", hint: "No uncommitted changes"))` | The same capsule from a row model; the hint is applied for you |
| `IconTile` | `IconTile(systemImage: "folder", tint: .blue, size: 32)` | Rounded square icon at the start of a row or card. 28 grid tile, 32 row, 36 card header |
| `IconButton` | `IconButton(systemImage: "trash", help: "Delete", tint: .red) { … }` | 24 × 24 icon action with hover background and hint |
| `OverflowMenu` | `OverflowMenu { Button("Copy", systemImage: "doc.on.doc") {} }` | Ellipsis menu, same footprint as `IconButton` |
| `StatusDot` | `StatusDot(color: .green)` | 7 pt dot for booted, success, failure |
| `SearchField` | `SearchField(text: $session.searchText)` | Header search and the Output panel search |
| `LinkButtonStyle` | `Button("Clear") {}.buttonStyle(LinkButtonStyle(.secondary))` or `(.accent, weight: .medium)` | Caption text link |

## Formatters (`SlateUI/Formatters/`)

| Helper | Gives |
|---|---|
| `date.relativeDescription`, `date.relativeDescription(to: now)` | "2 hr. ago", "yesterday"; mappers pass `now` |
| `ByteFormat.text(bytes)` | "1.2 GB" |
| `CountText.count(n, "app", "apps")`, `CountText.invariant(n, "worktrees")` | "1 app", "3 apps", "7 worktrees" |
| `DurationFormat.text(seconds)` | "320 ms", "4.1 s", "2 m 05 s" |
| `LogTimestamp.text(date)` | "14:03:22.118" |

No `DateFormatter`, `ByteCountFormatter` or hand-made pluralisation in a view or a mapper outside these files.

## Tint

`Tint` (`SlateUI/Tint.swift`) is the semantic colour enum used by models: `green`, `orange`, `red`, `blue`, `purple`,
`indigo`, `teal`, `pink`, `gray`, `secondary`. `tint.color` (`Tint+Color.swift`) is the only mapping to `Color`.

| Meaning | Tint |
|---|---|
| clean, success, booted | `.green` |
| uncommitted changes, booting, fast build | `.orange` |
| missing, failure, destructive | `.red` |
| current, target, branch | `.blue` |
| merged, scripts | `.purple` |
| project | `.indigo` |
| Claude agent worktree | `.teal` |
| neutral tag | `.secondary` |

Surfaces and chrome use `Theme` tokens, all mapped to system colours: `Theme.base` (header, toolbars, footer,
sidebar), `Theme.surface` (list, editor, fields), `Theme.border`, `Theme.text`, `Theme.secondaryText`,
`Theme.selection`, `Theme.codeBackground`, `Theme.hover`, `Theme.shadow`. Note status tints follow `docs/UX.md`
section 3: green done, blue in progress, orange in review, gray to do, red dropped (`NoteStatusText.tint`). Selection
is `Color.accentColor` (filled pill, white text) and `Color.accentColor.opacity(0.08)` for a highlighted row. No hex
colours outside `Theme`.

## Hints and truncation

Every icon without visible text explains itself on hover. `IconButton(help:)`, `OverflowMenu` and `ModelTag` do it;
anything else gets `.hint("…")`. Never `.help`: the system tooltip is slow and unreliable in the panel. A hint says
what happens, plus the git or simctl command when there is one.

Nothing a user acts on may be cut: labelled buttons get `.fixedSize()`, long button rows go into `ActionBar`, tag
rows into `FlowLayout`. Text may truncate (`lineLimit(1)`, `.truncationMode(.middle)` for names and paths) and then
shows the full text on hover with `.hintWhenTruncated(text)`. In a row the info column takes
`.frame(maxWidth: .infinity, alignment: .leading)` and the action buttons keep their size.

## Copy and toast

Static text a user may paste (path, branch, hash, device ID, user ID, command) gets `.copyOnClick(value, label:)`:
pointer cursor, underline on hover, click copies and shows the toast. `CopyOnClick` lives in SlateUI and knows no
`Toaster`: it calls the environment value `\.copyToPasteboard`, which `inject(_:)` sets to `toaster.copy(_:label:)`.
Copy buttons and menu items call `toaster.copy(value, label:)`. `Toaster` writes through `PasteboardWriter`
(SlatePresentation), the only file with `NSPasteboard`. No `copyOnClick` on text inside a row whose own
tap selects the row.

## Row pattern

```swift
struct WorktreeRow: View {
    @Environment(AppActions.self) private var actions
    @Environment(Toaster.self) private var toaster

    let model: WorktreeRowModel
    let isConfirmingDelete: Bool
    let onRequestDelete: () -> Void
    let onCancelDelete: () -> Void
    let onConfirmDelete: (_ deleteDerivedData: Bool, _ deleteBranch: Bool) -> Void

    @State private var deleteDerivedData = true
    @State private var deleteBranch = false

    var body: some View {
        RowContainer(isHighlighted: model.isBuildSource) { isHovered in
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 10) {
                    IconTile(systemImage: model.icon, tint: model.iconTint.color, size: 32)
                        .hint(model.iconHint)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(model.title).font(.callout.weight(.semibold)).lineLimit(1)
                            ForEach(model.titleTags, id: \.self) { ModelTag(model: $0) }
                        }
                        Text(model.displayPath).font(.caption.monospaced()).foregroundStyle(.secondary)
                            .lineLimit(1).truncationMode(.middle).copyOnClick(model.path, label: model.displayPath)
                        HStack(spacing: 6) { ForEach(model.statusTags, id: \.self) { ModelTag(model: $0) } }
                    }
                    Spacer(minLength: 4)
                    HoverActions(isVisible: isHovered && isConfirmingDelete == false, count: 2, spacing: 2) {
                        IconButton(systemImage: "play.fill", help: "Build & Run this worktree", tint: .green) {
                            actions.buildAndRun(worktreeID: model.id)
                        }
                        .disabled(model.canRun == false)
                        IconButton(systemImage: "trash", help: "Delete worktree", tint: .red) { onRequestDelete() }
                            .disabled(model.canDelete == false)
                    }
                }
                if isConfirmingDelete {
                    InlineConfirmation("Delete worktree \(model.title)?", confirmTitle: "Delete", confirmRole: .destructive, layout: .stacked, onCancel: onCancelDelete, onConfirm: { onConfirmDelete(deleteDerivedData, deleteBranch) }) {
                        ForEach(model.deleteWarnings, id: \.self) { Text("• \($0)").font(.caption).foregroundStyle(.red) }
                    } extra: {
                        Toggle(model.derivedDataLabel, isOn: $deleteDerivedData).disabled(model.hasDerivedData == false)
                    }
                }
            }
        }
        .contextMenu { … the same actions as the buttons … }
    }
}
```

- A row of `IconButton`s goes into `HoverActions(isVisible:count:spacing:)`: the buttons are built only while the row is hovered, and an empty frame of the same size keeps the layout still. `count` must match the number of buttons. Anything else toggles `opacity`. Never change the layout on hover.
- Never put many buttons under `ViewThatFits`: it builds and measures every variant. `ActionBar` uses `ActionBarLayout`, which builds two buttons per action.
- A selected or current row keeps its actions visible and gets `isHighlighted: true`.
- Right-click shows the same actions through `.contextMenu`. Enable rules come from the model, once.
- Dividers between rows: `Divider().padding(.leading, 56)`.
- The parent owns `@State private var confirmingDeleteID: Item.ID?` and animates with
  `.animation(.snappy(duration: 0.18), value: confirmingDeleteID)`. Destructive actions confirm inline; no `.alert`,
  no `.confirmationDialog`.

## Screen skeleton

```
VStack(spacing: 0) {
    ToolbarBar { … }
    Divider()
    ListState(failure:isLoading:loadingTitle:empty:noResultsFor:) {
        ScrollView { LazyVStack(spacing: 0) { rows } .padding(.vertical, 4) }
    }
}
.background(Theme.surface)
```

Card screens (Home) use `ScrollView { VStack(alignment: .leading, spacing: 18) { PanelCard { … } } .padding(14) }`
on `Theme.base`.

## Spacing and type

| Token | Value |
|---|---|
| Panel | 720 × 820 default, resizable, minimum 640 × 560 (`WindowLayout`) |
| Screen horizontal padding | 14 |
| Row vertical padding | 7 (dense) or 8 |
| Divider inset | 56 |
| Card padding | 12 (inside `PanelCard`) |
| Grid gap | 8, four columns |
| Corner radius | 10 cards and tiles, 8 inline bars, 7 tab buttons, 6 icon button hover |
| Row title | `.callout.weight(.semibold)` |
| Secondary line | `.caption` `.secondary`; paths, file names, hashes and commands `.monospaced()` |
| Detail line | `.caption2` `.secondary` |
| Section title | `.caption.weight(.semibold)` |

Slate follows the system appearance: every view has a light and a dark `#Preview` with `.preferredColorScheme`.
Never set `NSApp.appearance`. Layouts stretch: no fixed widths for rows or screens.

## Previews

```swift
#Preview {
    WorktreesView()
        .previewEnvironment()
}

#Preview {
    WorktreeRow(model: .preview, isConfirmingDelete: false, onRequestDelete: {}, onCancelDelete: {}, onConfirmDelete: { _, _ in })
        .previewEnvironment()
        .frame(width: 720)
}
```
