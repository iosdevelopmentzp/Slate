# ADR 0003: No App Sandbox, ad-hoc signing, no developer account

Status: accepted, 2026-10-16

## Context

The app runs `screencapture`, `git`, `open` and user scripts (actions), reads any folder the user picks as the vault, and reads iCloud Drive placeholders. The owner has no Apple Developer account. DevHub and Verba run the same way.

## Decision

- `ENABLE_APP_SANDBOX = NO`, hardened runtime off, "Sign to Run Locally". The app is installed by `Scripts/install.sh` into `/Applications`.
- No App Store, no notarization, no distribution beyond the owner's Macs.

## Consequences

- A rebuild changes the code signature; macOS may ask for the Screen Recording permission again. The bundle identifier stays stable to limit this.
- Features that need an entitlement (iCloud container, App Groups, push) are out of reach by design.
- If distribution is ever wanted, the Data layer is where sandbox adaptations would go (security-scoped bookmarks for the vault, an XPC helper for shell commands); the rest of the app would not change.
