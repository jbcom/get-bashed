---
title: MODULES.md — get-bashed
updated: 2026-04-15
status: current
---

# Runtime Modules

This document is maintained manually because the runtime modules are better described by behavior than by raw shdoc output.

| Module | Purpose | Flags | Startup side effects |
|---|---|---|---|
| `00-options` | Shell options, history, editor defaults | none | local shell settings only |
| `10-helpers` | PATH helpers and safe source helpers | none | defines helper functions |
| `20-path` | Core PATH construction, GNU tool preference, asdf paths | `GET_BASHED_GNU` | PATH mutation only |
| `30-buildflags` | Homebrew-derived build flags | `GET_BASHED_BUILD_FLAGS` | exports compile-time env vars |
| `40-completions` | Homebrew bash-completion and asdf completions | none | completion setup only |
| `50-tool-init` | Cargo env, starship, direnv | none | prompt / hook init if tools exist |
| `60-asdf` | asdf activation for git and Homebrew installs | none | sources `asdf.sh` if present |
| `65-tools` | Optional CLI bootstrap | `GET_BASHED_AUTO_TOOLS` | opt-in pinned npm installs if `asdf exec npm` is available |
| `66-doppler` | Explicit Doppler helper | `GET_BASHED_USE_DOPPLER` | defines `doppler_shell` only |
| `70-bash-it` | Optional bash-it init | `GET_BASHED_USE_BASH_IT` | sources bash-it if installed |
| `70-env` | Reserved non-secret shared env | none | currently no-op |
| `80-aliases` | Common aliases | none | aliases only |
| `90-functions` | Shell helper functions | none | defines functions only |
| `95-ssh-agent` | Optional ssh-agent bootstrap | `GET_BASHED_SSH_AGENT` | starts/reuses ssh-agent |
| `99-secrets` | Local secrets snippets | none | sources `~/.get-bashed/secrets.d/*.sh` |

## Notes

- The only secret-loading path is `99-secrets`.
- `doppler_env` does not inject secrets at startup.
- `auto_tools` remains opt-in, intentionally narrow, and checks pinned npm package state before installing.
