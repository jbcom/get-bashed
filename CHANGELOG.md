---
title: CHANGELOG.md — get-bashed
updated: 2026-04-10
status: current
---

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### ⚠️ BREAKING CHANGES
- **Consolidated Installation Prefix**: The environment is now strictly managed under a single prefix (`~/.get-bashed/` by default). Runtime modules have moved from `~/.bashrc.d/` to `~/.get-bashed/bashrc.d/`, and local secrets have moved from `~/.secrets.d/` to `~/.get-bashed/secrets.d/`. The installer includes automatic migration logic, but users are strongly advised to back up custom modules and secrets before upgrading.
- **Dotfile Symlinking Logic**: Dotfiles are no longer automatically copied to the home directory. Instead, they are copied to the managed prefix and, when `--link-dotfiles` is invoked, they are symlinked *from* the home directory *to* the managed prefix.

### Added
- Comprehensive Sphinx-based documentation published to GitHub Pages.
- Native `globstar` enablement for recursive file matching in Bash.
- Automatic integration of `eza` for modernized `ls` aliases when available.
- New `mkcd` command helper in `90-functions.sh`.
- Security enforcement: `secrets.d` and `.ssh/agent.sock` are now guaranteed to generate with restrictive (`700`/`600`) permissions to prevent exposing local credentials to other users on the system.

### Changed
- Massive performance optimization of interactive startup by eliminating multiple `$(brew --prefix <pkg>)` subshells in `.bash_profile` and `.bashrc`.
- Redesigned `install.bash` to safely escape injected variables like `--name` and `--email`, preventing unintended command execution.
- Redesigned `get_bashed_component` to rely on `$BASH_SOURCE` physical paths rather than trusting the `$GET_BASHED_HOME` environment variable.

<!-- Release Please inserts release sections above this line. -->

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
