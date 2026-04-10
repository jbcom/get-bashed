---
title: AGENTS.md
updated: 2026-04-09
status: current
domain: technical
---

# get-bashed — Extended AI Protocols

This file extends CLAUDE.md with architecture detail, patterns, and operational protocols for AI agents working in this repository.

## Architecture Overview

get-bashed has two distinct layers: the installer and the runtime.

### Installer Layer

`install.sh` is a POSIX-only bootstrap that locates or installs bash, then re-execs `install.bash`. `install.bash` is the full installer written in Bash 4+. It:

1. Parses CLI arguments for profiles, features, and installer lists.
2. Applies profiles (which set feature flag defaults).
3. Applies feature flag overrides.
4. Copies dotfiles and `bashrc.d/` to `PREFIX` (default `~/.get-bashed`).
5. Writes a generated config file `get-bashedrc.sh` encoding the resolved flags.
6. Optionally links dotfiles from `$HOME` to `~/.get-bashed` with backup.
7. Runs selected tool installers in dependency order.

### Runtime Layer

`bashrc` is sourced by the user's `~/.bashrc`. It reads `get-bashedrc.sh` (the generated config), then sources all files in `bashrc.d/` matching `[0-9][0-9]-*.sh` in sorted order.

`bash_profile` handles login shells: initializes Homebrew shellenv, then delegates to `bashrc`.

### Tool Registry

`installers/tools.sh` is the single source of truth for all installable tools. Each tool is declared with:

- `tool_register id desc deps platforms methods`
- `tool_pkgs id brew apt dnf yum pacman` (package names per manager)
- `tool_git id url` / `tool_curl id url cmd` (alternative sources)
- `tool_handler id fn` (custom installation function)
- `tool_opt_deps id "FLAG:dep,..."` (optional deps gated by feature flags)

`installers/_helpers.sh` contains platform detection helpers and all custom handler functions (`install_asdf`, `install_vimrc`, `install_shdoc`, `install_actionlint`, etc.).

### Config System

The installer writes `~/.get-bashed/get-bashedrc.sh` encoding:

| Variable | Meaning |
|---|---|
| `GET_BASHED_GNU` | Prefer GNU tools over BSD on macOS |
| `GET_BASHED_BUILD_FLAGS` | Export Homebrew build flags (CPPFLAGS, LDFLAGS, etc.) |
| `GET_BASHED_AUTO_TOOLS` | Auto-install optional CLIs |
| `GET_BASHED_SSH_AGENT` | Auto-start ssh-agent |
| `GET_BASHED_USE_DOPPLER` | Enable Doppler env injection |
| `GET_BASHED_USE_BASH_IT` | Enable bash-it framework |
| `GET_BASHED_GIT_SIGNING` | Enable GPG git signing |
| `GET_BASHED_VIMRC_MODE` | `awesome` or `basic` vimrc flavor |

Runtime modules read these flags and conditionally enable behavior.

### Profiles

Profiles live in `profiles/*.env`. Each defines `FEATURES` and `INSTALLS` values. Built-in profiles:

- `minimal`: all flags off, no tools.
- `dev`: GNU tools, build flags, auto tools. Installs dev CLI bundle.
- `ops`: dev plus SSH agent, Doppler, kubectl, helm, stern, terraform, awscli.

CLI `--features` and `--install` always override profile defaults.

### Module Load Order

| Range | Purpose |
|---|---|
| `00-` | Shell options, history, editor |
| `10-` | Shared helper functions |
| `20-` | PATH construction |
| `30-` | Build flags (conditional on `GET_BASHED_BUILD_FLAGS`) |
| `40-` | Shell completions |
| `50-` | Tool init (starship, direnv, cargo) |
| `60-` | asdf version manager activation |
| `65-` | Optional CLI tools |
| `66-` | Doppler env integration |
| `70-` | Aliases and env vars; bash-it init |
| `80-` | Extended aliases |
| `90-` | Shell functions |
| `95-` | SSH agent management |
| `99-` | Secrets sourcing from `secrets.d/` |

## Key Design Constraints

- `install.sh` must remain POSIX sh-compatible (no bashisms).
- `install.bash` requires Bash 4+ (enforced at runtime with `BASH_VERSINFO` check).
- All `bashrc.d/` modules must tolerate being sourced multiple times (idempotent).
- No module may hard-code a user's home directory or username.
- Tool installers prefer package managers over raw curl/git when available.
- Optional dependencies are gated by feature flags, not hard-wired.

## Data Flow

```
User runs install.sh
  └─> install.bash resolves profiles + features
      └─> copies bashrc.d/, dotfiles to ~/.get-bashed/
      └─> writes ~/.get-bashed/get-bashedrc.sh
      └─> runs tool installers (dependency order)
      └─> optionally symlinks ~/.bashrc -> ~/.get-bashed/bashrc

Shell startup
  └─> ~/.bashrc sources ~/.get-bashed/bashrc
      └─> sources get-bashedrc.sh (config)
      └─> sources bash_aliases
      └─> iterates bashrc.d/[0-9][0-9]-*.sh in order
          └─> each module reads GET_BASHED_* flags as needed
```

## Docs Pipeline

`scripts/gen-docs.sh` uses shdoc to generate `docs/INSTALLER.md`, `docs/INSTALLERS_HELPERS.md`, `docs/INSTALLERS.md`, and `docs/MODULES.md` from shell script annotations. It then regenerates `docs/INDEX.md`.

Run after any change to installer or module functions.

## CI Workflows

| Workflow | Trigger | Purpose |
|---|---|---|
| `ci.yml` | PR + push main | Lint (pre-commit), BATS tests, install verification |
| `docs.yml` | PR + push main | Build and publish docs to GitHub Pages |
| `pr-title.yml` | PR | Enforce Conventional Commits title format |
| `release-please.yml` | push main | Auto-manage release PRs and CHANGELOG |
| `release.yml` | version tag | Build release artifacts |
| `autofix.yml` | PR | Auto-apply fixable lint issues |
| `dependabot-automerge.yml` | Dependabot PR | Auto-merge minor/patch dependency updates |

## Testing Approach

Tests use BATS with pinned helper libraries (bats-support, bats-assert, bats-file). Each test runs the installer in an isolated temp `HOME` directory to prevent side effects on the host machine.

`scripts/test-setup.sh` fetches helper libraries at pinned SHAs. Do not change these without auditing the new commits.

## Security Surfaces

Changes to any of the following require extra scrutiny:

- `install.sh`, `install.bash`, `installers/` — arbitrary code execution during install
- `bashrc.d/99-secrets.sh` — sources everything in `secrets.d/`
- PATH construction (`bashrc.d/20-path.sh`) — ordering matters
- Any `curl`/`git` download — must be from trusted sources

See `SECURITY.md` for the full threat model and reporting guidance.
