# ADR 0005: A thin Markdown editor on TextKit 2, marks stay visible

Status: accepted, 2026-10-16. To amend after the M1.5 spike with the measured numbers and the chosen core.

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
