---
title: STATE.md — get-bashed
updated: 2026-04-10
status: current
---

# State

Current state and roadmap for the get-bashed project.

## Beta Milestone Reached
The project has achieved functional stability across the core installer and runtime layers. Idempotent wiring and cross-platform package management are verified.

## What is done

### Installer Core
- **POSIX Bootstrap**: `install.sh` handles initial environment probing and Bash acquisition.
- **Bash Installer**: `install.bash` provides full profile/feature resolution and config generation.
- **Idempotent Wiring**: Dotfiles are copied into `~/.get-bashed` with automated backups, then optionally symlinked into `$HOME` or sourced via snippets injected into shell profiles.
- **Dependency Registry**: Depth-first resolution with circular dependency detection.
- **Git Identity**: Integrated identity prompts and `gitconfig` template application.

### Runtime Modules
- **Ordered Loading**: Modular `bashrc.d/` structure (00-99).
- **Environment Management**: Robust PATH construction and Homebrew build flag injection.
- **Tool Integration**: Starship, direnv, and asdf version manager activation.
- **Secrets Protocol**: Isolated `secrets.d/` sourcing (git-ignored).

### CI/CD & Automation
- **Standardized Workflows**: Four-workflow pattern (CI, CD, Release, Automerge).
- **Security Gates**: Secret scanning (gitleaks) and workflow linting (actionlint).
- **Quality Gates**: BATS test suite and install verification on clean prefixes.

## Active Context
- **Refinement Phase**: Transitioning from functional completion to documentation and standard alignment.
- **Dogfooding**: Verifying local install stability after recent structural changes (symlink-only dotfiles).

## Recent Changes
- **Standardized Documentation**: Aligned all `.md` files with brand-aware headers and professional tone.
- **Workflow Consolidation**: Moved to the tight four-workflow pattern with pinned SHAs.
- **Release Please Config**: Standardized `release-please-config.json` (unhidden) alongside existing manifest.
- **Doc Index Protection**: Updated `gen-docs.sh` to preserve frontmatter in generated indices.

## What is next
- **Extended Test Coverage**: Expand BATS to cover runtime module behavior and flag side effects.
- **Profile Auditing**: Fine-tune default toolsets for `minimal`, `dev`, and `ops` profiles.
- **UX Polishing**: Improve the interactive `dialog` UI for more intuitive feature selection.

## Known issues
- `shdoc` is not available via standard package managers on macOS; requires local source build in CI.
- Runtime module `bashrc.d/` shdoc coverage is sparse; needs manual annotation pass.
- BATS helper libraries require periodic SHA auditing to stay secure.
