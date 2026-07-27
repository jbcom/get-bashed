---
title: Standards
updated: 2026-04-09
status: current
domain: technical
---

# Standards

Non-negotiable code quality constraints for get-bashed.

## Shell Language Rules

- `install.sh` must be strictly POSIX sh (`#!/bin/sh`, `set -eu`). No bashisms.
- `install.bash` and all `bashrc.d/` modules require Bash 4+ (`set -euo pipefail`).
- Scripts in `scripts/` and `installers/` use `#!/usr/bin/env bash` and `set -euo pipefail`.
- All scripts pass `shellcheck` with no warnings suppressed except documented exceptions.
- All scripts pass `bashate` (PEP 8 for shell). Max line length: 120.

## Idempotency

Every module and installer must be safe to run multiple times without unintended side effects.

- Modules: use include guards or conditional checks before modifying state.
- Installers: check if a tool is already installed before installing.
- File modifications: use marker-based `ensure_block` pattern (already in `install.bash`).
- Symlinks: check the current link target before replacing.

## Portability

- Never hardcode a user's home directory or username.
- Use `$HOME` and `$GET_BASHED_HOME` for all path references.
- Platform-specific behavior must be gated by `uname` checks or `command -v` probes.
- macOS/Linux/WSL differences must be handled without breaking any target.

## File Size

- Max 300 lines per file. Scripts that grow beyond this must be decomposed.

## Naming Conventions

- `bashrc.d/` modules: two-digit numeric prefix, hyphenated name, `.sh` extension (e.g., `20-path.sh`).
- Installer tools: snake_case IDs matching their primary CLI binary name where possible.
- Functions: snake_case. Internal (not intended for user use): prefix with `_`.
- Config env vars: `GET_BASHED_` prefix, ALL_CAPS, underscores.

## Documentation

- All public functions in `install.bash` and `installers/` must have shdoc annotations (`@description`, `@arg`, `@exitcode`, etc.).
- New runtime modules must be described in `docs/MODULES.md` or `TOOLS.md`.
- Run `./scripts/gen-docs.sh` after changing any annotated function.
- Docs must not lag behind the code. Outdated docs are bugs.

## Testing

- New installer flows need BATS test coverage.
- Tests run in an isolated temp `HOME`; they must not modify the developer's real home directory.
- Test helper libraries are pinned in `installers/sources.sh`. Do not update SHAs without auditing the new commits.

## Secrets Handling

- Secrets belong only in `~/.get-bashed/secrets.d/` (git-ignored).
- No secret values, API keys, or credentials may appear in any committed file.
- `bashrc.d/99-secrets.sh` is the only place that sources `secrets.d/`.
- Doppler is not auto-sourced at shell startup. Use `doppler_shell` for explicit injection.

## Installer Security

- Prefer package managers (brew, apt, dnf, yum, pacman) over raw curl or git downloads.
- When curl/git downloads are unavoidable, document the source and prefer pinned releases or pinned refs from `installers/sources.sh`.
- Avoid `eval` with untrusted input. Validate all user-supplied arguments that affect execution paths.
- Do not suppress `set -e` behavior in installers without an explicit inline comment explaining why.

## CI Gates

All PRs must pass before merge:

- `quality` job: shellcheck, bashate, actionlint, gitleaks (via pre-commit), BATS, install verification, docs generation, and docs build on Ubuntu and macOS.
- `sonarqube` job: repository scan after the quality matrix succeeds.

## Commit Style

Conventional Commits format is expected. Examples:

```
feat: add shdoc auto-install handler
fix: correct brew path detection on arm64
docs: update CONFIG.md with all feature flags
refactor: extract pkg_install into _helpers.sh
test: add coverage for --link-dotfiles flow
ci: pin checkout action to v6 SHA
chore: bump bats-assert pinned SHA
```

## Pull Requests

- Keep PRs focused and small where possible.
- Include a clear summary of what changed and why.
- Note any install behavior changes, new env vars, or security-sensitive modifications.
- Update docs (shdoc annotations, `TOOLS.md`, `docs/`) in the same PR as behavior changes.
