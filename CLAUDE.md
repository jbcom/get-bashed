---
title: CLAUDE.md
updated: 2026-04-09
status: current
domain: technical
---

# get-bashed — Agent Entry Point

get-bashed is a modular, portable Bash environment. The installer copies dotfiles and ordered runtime modules to `~/.get-bashed`, wires shell startup, and optionally installs tools via a centralized registry.

## Critical Rules

- Never hardcode user paths. Use `$HOME` and `$GET_BASHED_HOME`.
- Installer scripts must remain idempotent — safe to re-run without side effects.
- POSIX-only code belongs in `install.sh`; Bash 4+ is required for `install.bash` and all `bashrc.d/` modules.
- Secrets live only in `~/.get-bashed/secrets.d/` (git-ignored). Never commit them.
- Shell startup modules must be safe to source repeatedly. No one-shot side effects.

## Project Layout

```
bashrc               # Interactive shell entrypoint
bash_profile         # Login shell entrypoint (delegates to bashrc)
bash_aliases         # Aliases sourced by bashrc
inputrc              # Readline config
vimrc                # Vim config
gitconfig            # Git config template
bashrc.d/            # Ordered runtime modules (00- to 99-)
installers/
  tools.sh           # Centralized tool registry
  _helpers.sh        # Platform helpers and tool handlers
profiles/            # Profile .env files (minimal, dev, ops)
bin/                 # Portable helper scripts
scripts/             # CI, docs, and test helpers
tests/               # BATS test suite
docs/                # Generated and hand-authored docs
secrets.d/           # Local secrets (git-ignored)
install.sh           # POSIX bootstrap (re-execs install.bash)
install.bash         # Full installer, config writer, tool runner
Makefile             # docs, lint, test
```

## Key Commands

```bash
# Install locally for development/testing
./install.sh --prefix ~/.get-bashed

# Run tests
make test
# or
./scripts/test-setup.sh && bats tests

# Lint
make lint
# or
pre-commit run --all-files

# Generate shdoc docs
make docs
# or
./scripts/gen-docs.sh

# Dry run with installer list
./install.sh --dry-run --list

# Full dev install
./install.sh --profiles dev --link-dotfiles --name "Name" --email "email@example.com"
```

## Adding a Runtime Module

1. Create `bashrc.d/NN-name.sh` with two-digit numeric prefix.
2. Keep idempotent; guard against repeated sourcing.
3. Add shdoc annotations for any exported functions.
4. Document new env vars in `docs/MODULES.md` or `TOOLS.md`.

## Adding an Installer

1. Register with `tool_register` / `tool_pkgs` / `tool_handler` in `installers/tools.sh`.
2. Express dependencies via `TOOL_DEPS` and optional deps via `tool_opt_deps`.
3. Add a handler function to `installers/_helpers.sh` if custom logic is needed.
4. Re-run `./scripts/gen-docs.sh` after adding shdoc annotations.

## CI

- `scripts/ci-setup.sh` bootstraps tools into `GET_BASHED_HOME` on runners.
- `scripts/pre-commit-ci.sh` runs pre-commit in CI.
- `scripts/verify-install.sh` validates installer output wiring.
- `scripts/test-setup.sh` fetches pinned Bats helper libraries.

## Testing

Run BATS suite:

```bash
./scripts/test-setup.sh
bats tests
```

Tests use a temp `HOME` to isolate side effects.

## Commit Style

Conventional Commits: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`, `ci:`.
