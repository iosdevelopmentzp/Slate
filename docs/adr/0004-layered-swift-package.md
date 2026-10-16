# ADR 0004: Layered local Swift package, the DevHub contract

Status: accepted, 2026-10-16

## Context

The owner wants a clean architecture that an AI agent can extend without breaking it, with the compiler enforcing boundaries. DevHub already has such a contract (`../DevHub/docs/ARCHITECTURE.md`): one local package, one module per layer, ports and use cases in Domain, live implementations in Data, `@Observable` stores in Presentation, a composition root, Swift Testing with spies, and a layer check script.

## Decision

- Slate uses the same contract with the same module names pattern: `SlateDomain`, `SlateData`, `SlateMocks`, `SlateUI`, `SlatePresentation`, `SlateComposition`, `SlateTestSupport`.
- Two additions: `SlateEditor` (the TextKit 2 editor, independent of the package, replaceable) and `SlateCLI` (an executable that reuses Domain and Data).
- Swift 6 language mode, `package` access between modules, MainActor by default in UI modules, nonisolated in the others.
- Skills, rules, hooks and scripts are copied from DevHub and adapted, not written again. The copy happened at bootstrap; each skill is reviewed against Slate when its topic is first touched.

## Consequences

- An agent that knows DevHub knows Slate. The `/add-feature`, `/add-use-case`, `/testing` skills apply.
- Some early boilerplate (ports, spies, assembly) before the first feature; this is paid once in M0 and M1.
- The editor can be swapped (own code or an open-source engine) without touching stores or views.
