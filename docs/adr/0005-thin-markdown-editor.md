# ADR 0005: A thin Markdown editor on TextKit 2, marks stay visible

Status: accepted, 2026-10-16. Amended 2026-10-16 after the M1.5 spike: the own core is chosen.

## Context

The owner asked for a notes app, not an editor. A rich text or live-preview editor is the largest risk in the project: months of work in other apps. At the same time a developer needs code blocks with highlighting, checklists, images and links to look right while typing.

## Decision

- The editor edits Markdown source. Marks (`#`, `**`, backticks) stay visible in a lighter colour; headings, emphasis, code, links, quotes and lists are styled in place. Images render under their line; checkboxes render over their characters; code fences get a background, highlighting and a copy button.
- Built on `NSTextView` with TextKit 2, styling applied per paragraph through the content storage delegate (display only), custom layout fragments for images and checkboxes, an own regex highlighter per language. No JavaScript engine.
- The editor is its own module `SlateEditor` with a small contract (`ARCHITECTURE.md` section 6.1). It knows nothing about notes or files.
- Live preview (hiding marks) is P2 and only after v1 is stable.
- M1.5 is a time-boxed spike: own core against the open-source `MarkdownEngine` package. The one with acceptable latency and the smaller surface wins; a tie goes to the own core (no dependency). The result amends this ADR.

## Consequences

- Fast to build, fast at runtime, predictable: what you type is what is saved.
- Less visual polish than Bear or Craft; acceptable for a developer's notes.
- Tables, math and diagrams are not rendered in v1.

## Alternatives rejected

- SwiftUI `TextEditor` with `AttributedString`: no per-paragraph display styling, no custom fragments, less control over paste and lists.
- WYSIWYG on `NSTextView` with Markdown import and export: loses source fidelity and doubles the format surface.
- `STTextView`: dual licence and not needed once `NSTextView` runs on TextKit 2.

## Amendment: M1.5 spike result (2026-10-16)

Two throwaway branches rendered the same 5,000-line fixture (headings, lists, checkboxes, quotes, Swift fences, images) in an 800 × 600 window on Apple silicon. Numbers from a test with `ContinuousClock`: open is "set the text, lay out the viewport, draw"; a keystroke is "insert one character in the middle, lay out the viewport, draw", 60 samples.

| Measure | (a) own core (`spike/own-core`) | (b) `MarkdownEngine` 0.9.0 (`spike/markdown-engine`) |
|---|---|---|
| Open | 71 ms | 975 ms |
| Keystroke, median | 2.2 ms | 79 ms |
| Keystroke, 97th percentile | 2.6 ms | 82 ms |
| Type a fence opener above 2,500 lines | 2.7 ms | 406 ms |
| Size | about 900 lines | about 13,800 lines plus two transitive packages |

Decision: **own core**. It meets the 16 ms budget with a wide margin and adds no dependency.

Other facts found in the spike:

- `MarkdownEngine` is Apache 2.0, not MIT. Its wikilink storage form is `[[Name|<id>]]`, which conflicts with the alias form `[[Stem|alias]]` of `STORAGE-FORMAT.md` section 2.4. Its ready-made code highlighting uses HighlighterSwift, which runs highlight.js in JavaScriptCore; `ARCHITECTURE.md` section 14 excludes a JavaScript engine.
- Own core: styling through `NSTextContentStorageDelegate.textContentStorage(_:textParagraphWith:)` works. `FenceTracker` updates in `textStorage(_:willProcessEditing:…)`, before the content storage asks for paragraphs. Lines below the edit whose fence state changed are regenerated with `performEditingTransaction { textStorage.edited(.editedAttributes, …) }` from `textDidChange`.
- The image check of `PLAYBOOK.md` section 9: `paragraphSpacing` on the image line does grow the layout fragment frame (a 200 pt image line became 231 pt high and the next line starts below it). No attachment fallback is needed.
- `NSTextLayoutFragment` is not main-actor isolated: its subclass is `nonisolated`, and so are the value types it reads (`LineDecoration`, `EditorColors`).
- The fragment frame is only as wide as the text, so a code block background takes the width of the text container.
