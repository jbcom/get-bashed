---
title: TOOLS.md — get-bashed
updated: 2026-04-15
status: current
---

# Tools & Language Management

This project favors **asdf** for multi-version language management and keeps shell behavior deterministic.

## Bash

It is recommended to install the latest GNU Bash for full compatibility:
```bash
./install.sh --install bash
```

## asdf

- Recommended for: Node.js, Python, Java, and other multi-version runtimes.
- `bashrc.d/60-asdf.sh` activates asdf when present.
- get-bashed pins default `asdf` runtime versions in `installers/sources.sh` for the built-in `nodejs`, `python`, and `java` installers.

Example:
```bash
asdf plugin add nodejs
asdf install nodejs 24.14.1
asdf set --home nodejs 24.14.1
```

## Build Flags (macOS)

When building runtimes from source (Python, Ruby, etc.), macOS often requires explicit paths to Homebrew libraries. If you enable:

```bash
GET_BASHED_BUILD_FLAGS=1
```

then `bashrc.d/30-buildflags.sh` exports:
- `CPPFLAGS`, `LDFLAGS`, `PKG_CONFIG_PATH`
- `LIBRARY_PATH`, `CPATH`
- `PYTHON_CONFIGURE_OPTS`

These are derived from Homebrew prefixes for `openssl@3`, `readline`, `gettext`, and `zstd`.

## GNU Tooling (macOS)

If you want GNU tooling on macOS, install the core GNU packages via Homebrew and enable:

```bash
GET_BASHED_GNU=1
```

This adds `coreutils`, `findutils`, `gnu-sed`, and `gnu-tar` gnubin paths ahead of BSD tools.

## Optional CLI Tools

`bashrc.d/65-tools.sh` includes an opt-in helper to install optional CLIs using Node:
- `@google/gemini-cli@0.38.1`
- `@sonar/scan@4.3.6`

Those package specs are pinned in `installers/sources.sh`, written to `~/.get-bashed/get-bashed-pins.sh` by the installer, and only used when `GET_BASHED_AUTO_TOOLS=1` and `asdf exec npm` is already available. The runtime checks whether the exact pinned package is already installed before attempting a global install.

## bash-it

Install bash-it and enable it:
```bash
./install.sh --install bash_it
./install.sh --features bash_it
```

Enable components via search:
```bash
get_bashed_component enable git docker
```
Install `bash_it` first if you want bash-it search-backed enable/disable behavior:
```bash
./install.sh --install bash_it --features bash_it
```

## Vim (amix/vimrc)

Install the Awesome vimrc:
```bash
./install.sh --install vimrc
```

Install the Basic vimrc:
```bash
./install.sh --install vimrc --vimrc-mode basic
```

## Doppler (Optional)

If you use Doppler for secrets, install the CLI and enable:

```bash
GET_BASHED_USE_DOPPLER=1
```

You can install via the installer:

```bash
./install.sh --install doppler
```

Note: startup does not auto-fetch or inject Doppler secrets. Use `doppler_shell` to start a doppler-enabled subshell.

## Curation Policy

- Keep `bin/` small and portable.
- Prefer scripts that are OS-safe, dependency-light, and non-sensitive.

## Installer UI

If you pass `--with-ui`, the installer will try to use a curses UI (`dialog`).
If `dialog` is not present, it will attempt to install it using the detected
package manager. Otherwise it falls back to plain prompts.

## Listing and Dry Run

- `./install.sh` is a POSIX bootstrap that runs `install.bash`.
- `./install.sh --list` shows the catalog of installers.
- `./install.sh --list-profiles` shows available profiles.
- `./install.sh --list-features` shows available features.
- `./install.sh --list-installers` shows the installer catalog.
- `./install.sh --dry-run --install <list>` shows what would be installed without writing files.
- `./install.sh --link-dotfiles` backs up and symlinks shell dotfiles to `~/.get-bashed`.
- `./install.sh --name "Full Name" --email "me@example.com"` sets git identity.

## Docs

Generate docs with:
```bash
./scripts/gen-docs.sh
```

## Feature Names

Use `--features` with comma-separated values:
- `gnu_over_bsd`
- `build_flags`
- `auto_tools`
- `ssh_agent`
- `doppler_env`
- `bash_it`
- `git_signing`
- `dev_tools`
- `ops_tools`

## Language Installers

Installers exist for `nodejs`, `python`, and `java`. If `asdf` is installed, they
use repo-pinned default versions. Otherwise they fall back to the system package manager.

## Pin Maintenance

The pinned git refs, BATS helper SHAs, pip and pipx package specs, optional Node CLI package specs, and default `asdf` runtime versions live in
`installers/sources.sh`.

The `actionlint` fallback tarball is pinned by version and verified against manifest SHA-256 values before extraction.
Managed git-backed installs such as `bash_it` and `asdf` are realigned to their pinned refs on rerun instead of trusting an existing clone blindly.

To print manifest-ready `asdf` runtime pins from your current installed versions:
```bash
bin/gen_tool_versions
```

## Profiles

Use `--profiles minimal|dev|ops` to apply presets before any manual selections.
