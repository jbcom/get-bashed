---
title: CHANGELOG.md — get-bashed
updated: 2026-04-10
status: current
---

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!-- Release Please inserts release sections above this line. -->

## [0.2.0](https://github.com/jbcom/get-bashed/compare/v0.1.0...v0.2.0) (2026-04-10)


### Features

* comprehensive codebase refinement for security, performance, and robustness ([#10](https://github.com/jbcom/get-bashed/issues/10)) ([98d6fec](https://github.com/jbcom/get-bashed/commit/98d6fecd24dffab963b9bc71a80400d076843adc))
* **installer:** add legacy migration and prevent recursive loops ([#12](https://github.com/jbcom/get-bashed/issues/12)) ([3190d63](https://github.com/jbcom/get-bashed/commit/3190d633137f998b3154ba4c8a3deff1c2238325))

## [Unreleased]

## [0.1.0] — 2026-02-03

### Added

- Modular `bashrc.d/` runtime loaded in lexicographic order (`00-` through `99-`).
- `install.sh` POSIX bootstrap that locates or installs bash, then re-execs `install.bash`.
- `install.bash` full installer: profiles, feature flags, tool registry, dotfile wiring.
- Centralized tool registry in `installers/tools.sh` with per-tool package names, dependencies, optional deps, and custom handlers.
- Shared platform helpers and tool handlers in `installers/_helpers.sh`.
- Built-in profiles: `minimal`, `dev`, `ops` (via `profiles/*.env`).
- Feature flags: `gnu_over_bsd`, `build_flags`, `auto_tools`, `ssh_agent`, `doppler_env`, `bash_it`, `git_signing`, `dev_tools`, `ops_tools`.
- Optional dependency gating by feature flag (e.g., `git_signing` adds `gnupg`).
- `--link-dotfiles` option to symlink dotfiles from `$HOME` into `~/.get-bashed` with automatic backups.
- `--name` / `--email` flags to write git identity into the installed `gitconfig`.
- `--vimrc-mode` flag for `awesome` (default) or `basic` vimrc flavor.
- `--with-ui` flag for curses `dialog` interactive setup.
- `--dry-run`, `--list`, `--list-profiles`, `--list-features`, `--list-installers` discovery flags.
- `--auto` / `--yes` flags for non-interactive installs.
- `get_bashed_component` helper for enabling bash-it components or falling back to asdf/brew/system installs.
- `doppler_shell` function for launching a Doppler-injected subshell on demand.
- SSH agent reuse logic in `bashrc.d/95-ssh-agent.sh`.
- Cargo env sourcing and starship/direnv init in `bashrc.d/50-tool-init.sh`.
- Secrets sourced from `~/.get-bashed/secrets.d/` in `bashrc.d/99-secrets.sh`.
- BATS test suite with `bats-support`, `bats-assert`, `bats-file` at pinned SHAs.
- `scripts/test-setup.sh` fetches pinned Bats helper libraries.
- `scripts/verify-install.sh` validates installer output wiring.
- `scripts/ci-setup.sh` bootstraps tools into `GET_BASHED_HOME` for CI runners.
- `scripts/pre-commit-ci.sh` runs pre-commit in CI.
- `scripts/gen-docs.sh` generates shdoc-based API docs into `docs/`.
- `scripts/package.sh` builds a release tarball.
- GitHub Actions workflows: `ci.yml`, `docs.yml`, `pr-title.yml`, `release-please.yml`, `release.yml`, `autofix.yml`, `dependabot-automerge.yml`.
- `SECURITY.md` with threat model and vulnerability reporting guidance.
- `CONTRIBUTING.md` with style, design principles, and PR guidelines.
- `TOOLS.md` documenting tool management, profiles, and feature names.
- `CODEOWNERS` for review requirements.

[Unreleased]: https://github.com/jbcom/get-bashed/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/jbcom/get-bashed/releases/tag/v0.1.0
