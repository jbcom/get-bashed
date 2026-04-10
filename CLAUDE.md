---
title: CLAUDE.md — get-bashed
updated: 2026-04-10
status: current
---

# get-bashed — Agent Entry Point

get-bashed is a modular, portable Bash environment. The installer copies dotfiles and ordered runtime modules to `~/.get-bashed`, wires shell startup, and optionally installs tools via a centralized registry.

## Quick orientation

```
bashrc               # Interactive shell entrypoint
bash_profile         # Login shell entrypoint (delegates to bashrc)
bashrc.d/            # Ordered runtime modules (00- to 99-)
installers/          # Tool registry and platform handlers
profiles/            # Profile .env files (minimal, dev, ops)
bin/                 # Portable helper scripts
scripts/             # CI, docs, and test helpers
tests/               # BATS test suite
docs/                # Hand-authored and system docs
install.sh           # POSIX bootstrap (re-execs install.bash)
install.bash         # Full installer and config writer
```

## Critical rules

- **No hardcoded paths** — always use `$HOME` and `$GET_BASHED_HOME`
- **Idempotency is mandatory** — every script and module must be safe to re-run
- **Strict shell boundaries** — `install.sh` is POSIX-only; everything else is Bash 4+
- **Conventional commits** — `feat:`, `fix:`, `chore:`, `docs:`, etc.
- **300 LOC max per file** — enforced by standards

## Commands

```bash
./install.sh --prefix ~/.get-bashed     # Local dev install
make test                               # Run BATS tests
make lint                               # Run pre-commit hooks
make docs                               # Build documentation

./install.sh --dry-run --list           # Inspect installer registry
./install.sh --profiles dev --auto      # Full developer workstation setup
```

## Workflows

- **Adding a Module** — Create `bashrc.d/NN-name.sh`; must be idempotent
- **Adding an Installer** — Register in `installers/tools.sh`; use handlers in `_helpers.sh`
- **Updating Docs** — Edit `.md` files in `docs/` manually; use `make docs` for generated references
- **Testing** — BATS suite runs in isolated temp `HOME` to prevent side effects
