# ADR 0024: Mermaid diagrams in code blocks

Status: accepted, 2026-11-08. The owner allowed the library on 2026-11-08.

## Context

Task notes describe flows, states and modules. A diagram written as text (Mermaid) lives in the Markdown file, shows in `git diff`, and agents write it well. GitHub, GitLab and Obsidian draw ` ```mermaid ` blocks. Slate showed the code only. There is no native Swift renderer; the reference renderer is the JavaScript library `mermaid`.

## Decision

1. Slate ships `mermaid` 12.2.0 (MIT, released 2026-10-13) as one file, `Packages/SlateKit/Sources/SlateEditor/Diagrams/Resources/mermaid.min.js`, with its licence next to it. All its dependencies are inside that file. `Packages/SlateKit/Vendored.lock` holds the version, the SHA-256 and the download address; `Scripts/check-deps.sh` fails when the file does not match. A new version needs the owner's permission, as for a Swift package.
2. The file format does not change. A diagram is a fenced code block with the language `mermaid`.
3. `MermaidRenderer` draws in one hidden `WKWebView` per editor, loaded from the bundled `diagram.html`. The page has no network: a content rule list blocks `http`, `https`, `ws` and `ftp` loads, navigation away from the page is cancelled, the data store is not persistent, and Mermaid runs with `securityLevel: "strict"`. The result is a vector PDF of the SVG, drawn as an `NSImage`.
4. The editor draws the diagram at the top of the code block. The code shows only while the caret is in the block; outside it the code text gets a near-zero line height and a clear colour, which are display attributes (`slate.diagram`, `slate.diagramArea`, `slate.diagramHidden`) that the writer ignores. A diagram is drawn again 0.4 s after the text changes, with the dark or the light theme of the window. A broken diagram keeps the last picture and shows the error under it.
5. `import WebKit` is allowed only in `SlateEditor/Diagrams/` (`Scripts/check-layers.sh`).

## Consequences

- The app is about 5 MB larger. The first diagram of an editor waits for the page to load (under a second).
- Copy for Jira and Copy for Slack copy the diagram as code; Jira's wiki markup has no Mermaid.
- Known security notices of `mermaid` (XSS, CSS injection, prototype pollution, endless loops) are fixed in 11.16.1 and older versions; 12.2.0 has them all. The notes are the owner's and their agents', and the page has no network, so a bad diagram can at most hang its own web view.
