# ADR 0006: The app knows no project

Status: accepted, 2026-10-16

## Context

The owner uses Slate for work on a product with its own ticket keys, hosts and names, but wants the app and its repository to stay anonymous and reusable: nothing in the code, the resources, the tests, the docs or the commit history may name a company, a product, a host, a ticket prefix, a branch pattern or a person.

## Decision

- Every project fact comes from Settings (tracker base URL and key pattern, git host and project path, branch pattern) or from files in the user's vault (`.slate/links.json`, `.slate/types/`, `.slate/actions/`, `_templates/`). Defaults are generated from Settings at first launch, not shipped as constants.
- Examples in docs, tests and fixtures use `ABC-123`, `example.atlassian.net`, `gitlab.example.com`, `feature/ABC-123-short-title`.
- No build-time word list (the owner declined one). The rule is kept by reading the diff before each commit; generated file headers with an author name are removed.
- Commit messages and the changelog follow the same rule.

## Consequences

- The app works for any tracker that has a key pattern and an issue URL, and any git host with a merge request URL.
- A few more settings fields in H2 and a first-launch step that writes `links.json`.
