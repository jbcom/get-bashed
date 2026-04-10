---
title: Design
updated: 2026-04-09
status: current
domain: product
---

# Design

## What get-bashed is

get-bashed is a portable, modular Bash environment that installs reproducibly on any machine. It is designed for engineers who want a consistent shell setup across macOS, Linux, and WSL without writing and maintaining a personal dotfile framework from scratch.

The core value proposition:

- Ordered, legible runtime modules instead of a monolithic `.bashrc`.
- A reproducible installer that expresses your choices in a generated config file.
- A curated tool registry that installs the right way on the right platform.
- Safe defaults: nothing is turned on that you did not ask for.

## What get-bashed is not

- A replacement for your existing dotfile manager. It can coexist with one.
- A framework that assumes a particular prompt, editor, or workflow.
- A one-size-fits-all config. Profiles and feature flags exist specifically to avoid that.
- A tool that makes privileged changes without your knowledge. Every path modification, file creation, and tool installation is explicit.

## Design principles

### Explicit over implicit

No behavior is enabled unless the user opts in via a profile, feature flag, or installer argument. The generated `get-bashedrc.sh` is the record of what was chosen. Users can inspect and edit it directly.

### Idempotent by default

The installer and every runtime module must be safe to run or source multiple times. Re-running the installer with `--force` should not destroy user state — it should reset to the requested configuration.

### Portable over convenient

Shell modules avoid platform-specific assumptions. When platform-specific behavior is needed, it is gated by explicit checks (`uname`, `command -v`, feature flags). No module assumes Homebrew is present on Linux or that apt is available on macOS.

### Minimal privilege

The installer runs as the current user. It calls `sudo` only when a package manager requires it, and only within well-defined helper functions. Nothing is installed system-wide by default.

### Secrets stay local

Secrets belong in `~/.get-bashed/secrets.d/` which is git-ignored. No auto-sourcing of secret providers (Doppler, 1Password, etc.) happens at shell startup. Explicit `doppler_shell` is provided for on-demand injection.

## User experience goals

### Installation

The install experience should:

- Work from a single `curl | sh` command on a fresh machine.
- Let the user review the installer before running it.
- Succeed non-interactively (`--auto --yes`) for CI and provisioning scripts.
- Offer a curses UI (`--with-ui`) for exploratory first installs.
- Produce a clear, inspectable output in `~/.get-bashed/`.

### Shell startup

Shell startup should:

- Be fast. Modules that do heavy work are conditional.
- Be predictable. Load order is deterministic and visible.
- Not break existing configs. The installer appends source snippets idempotently rather than overwriting `~/.bashrc`.

### Tool management

Tool installation should:

- Prefer the platform package manager.
- Fall back gracefully through alternatives (asdf, git, curl).
- Express dependencies explicitly rather than silently pulling in requirements.
- Work in offline or restricted environments where possible.

## Non-goals

- Supporting `zsh`, `fish`, or other shells. This is a Bash environment.
- Managing system-level config (network, firewall, system packages unrelated to developer tooling).
- Automatically updating itself or its tools. Updates are explicit.
- Providing a UI for ongoing management. The config file is the UI.
