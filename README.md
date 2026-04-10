---
title: README.md — get-bashed
updated: 2026-04-10
status: current
---

# get-bashed

<p align="center">
  <img src="assets/logo.png" alt="get-bashed logo" width="300" />
</p>

[![CI](https://img.shields.io/github/actions/workflow/status/jbcom/get-bashed/ci.yml?branch=main)](https://github.com/jbcom/get-bashed/actions/workflows/ci.yml)
[![Docs](https://img.shields.io/github/actions/workflow/status/jbcom/get-bashed/docs.yml?branch=main)](https://github.com/jbcom/get-bashed/actions/workflows/docs.yml)
[![Release](https://img.shields.io/github/v/release/jbcom/get-bashed?display_name=tag&sort=semver)](https://github.com/jbcom/get-bashed/releases)
[![License](https://img.shields.io/github/license/jbcom/get-bashed)](LICENSE)

A modular, portable Bash environment you can install on any machine. get-bashed gives you clean shell defaults, ordered runtime modules, a centralized tool installer, and reproducible configuration — without touching anything you do not explicitly ask it to touch.

## What it is

- Ordered `bashrc.d/` modules loaded by `bashrc` at shell startup.
- A generated config file (`get-bashedrc.sh`) that encodes your feature choices.
- A dependency-aware tool installer driven by a single registry (`installers/tools.sh`).
- Profile presets (`minimal`, `dev`, `ops`) with per-feature overrides.
- Optional dotfile symlinking from `$HOME` into `~/.get-bashed` with automatic backups.
- Cross-platform: macOS, Linux, WSL.

## What it is not

- A replacement for your existing dotfile manager (it can coexist).
- A framework that auto-sources secrets or alters behavior without explicit opt-in.
- Opinionated about your prompt or editor — both are optional and configurable.

## Quick start

```bash
curl -fsSL -o install.sh https://raw.githubusercontent.com/jbcom/get-bashed/main/install.sh
# Review install.sh before running
sh install.sh
```

To symlink shell dotfiles and set git identity:

```bash
sh install.sh --link-dotfiles --name "Jane Doe" --email "jane@example.com"
```

To install with the `dev` profile (GNU tools, build flags, dev CLI bundle):

```bash
sh install.sh --profiles dev --link-dotfiles --name "Jane Doe" --email "jane@example.com"
```

## Profiles

Profiles set feature flag defaults and an installer list. CLI flags always override profile defaults.

| Profile | Features | Use case |
|---|---|---|
| `minimal` | all off | Minimal defaults, no tool installs |
| `dev` | GNU tools, build flags, auto tools | Developer workstation |
| `ops` | dev + SSH agent, Doppler | Ops/platform workstation |

```bash
sh install.sh --profiles ops
```

## Features

Enable or disable individual behaviors with `--features`. Prefix `no-` to disable.

| Feature | Description |
|---|---|
| `gnu_over_bsd` | Prefer GNU coreutils/sed/tar over BSD equivalents on macOS |
| `build_flags` | Export Homebrew build paths (CPPFLAGS, LDFLAGS, PKG_CONFIG_PATH) |
| `auto_tools` | Auto-install optional CLI tools at shell startup |
| `ssh_agent` | Auto-start and reuse `ssh-agent` |
| `doppler_env` | Enable Doppler env integration (does not auto-source on startup) |
| `bash_it` | Enable the bash-it framework if installed |
| `git_signing` | Install gnupg and enable GPG git signing |
| `dev_tools` | Bundle: rg, fd, bat, fzf, jq, yq, tree, direnv, starship, nodejs, python, bash |
| `ops_tools` | Bundle: gh, git-lfs, terraform, awscli, kubectl, helm, stern, doppler, nodejs, python, java, bash |

```bash
sh install.sh --profiles minimal --features gnu_over_bsd,ssh_agent
```

## Tool installer

Install any combination of tools from the registry:

```bash
sh install.sh --install brew,asdf,rg,fd,bat,fzf,jq
```

The installer resolves dependencies in order and uses the best available method (brew, apt, dnf, yum, pacman, pipx, git, curl).

Available tools: `brew`, `asdf`, `bash`, `bash_it`, `vimrc`, `shdoc`, `dialog`, `pipx`, `pre_commit`, `bashate`, `shellcheck`, `actionlint`, `bats`, `curl`, `wget`, `gnupg`, `gnu_tools`, `git`, `git_lfs`, `gh`, `direnv`, `starship`, `rg`, `fd`, `bat`, `fzf`, `jq`, `yq`, `tree`, `nodejs`, `python`, `java`, `terraform`, `awscli`, `kubectl`, `helm`, `stern`, `doppler`.

Inspect without installing:

```bash
sh install.sh --list
sh install.sh --list-profiles
sh install.sh --list-features
sh install.sh --list-installers
sh install.sh --dry-run --install rg,fd,bat
```

## Installer options

| Flag | Description |
|---|---|
| `--prefix PATH` | Install to PATH instead of `~/.get-bashed` |
| `--profiles NAMES` | Comma list of profiles to apply |
| `--features LIST` | Comma list of features (supports `no-` prefix) |
| `--install LIST` | Comma list of tools to install |
| `--link-dotfiles` | Symlink dotfiles from `$HOME` to `~/.get-bashed` |
| `--name NAME` | Set `user.name` in the installed gitconfig |
| `--email EMAIL` | Set `user.email` in the installed gitconfig |
| `--vimrc-mode MODE` | `awesome` (default) or `basic` vimrc flavor |
| `--with-ui` | Use curses dialog UI if `dialog` is available |
| `--auto` / `-a` | Disable interactive prompts |
| `--yes` / `-y` | Auto-accept all prompts |
| `--force` | Overwrite existing files |
| `--dry-run` | Print what would happen, make no changes |

## Runtime modules

Modules in `bashrc.d/` load in numeric order at shell startup. You can add your own by creating a file with the next available prefix. Each module reads `GET_BASHED_*` flags from `get-bashedrc.sh` and enables behavior conditionally.

## Secrets

Place local secrets in `~/.get-bashed/secrets.d/*.sh`. The installer creates a starter file `secrets.d/00-local.sh`. All files in `secrets.d/` are sourced by `bashrc.d/99-secrets.sh`. The `secrets.d/` directory is git-ignored and never committed.

## Configuration

After install, `~/.get-bashed/get-bashedrc.sh` holds the resolved config. You can edit it directly to change behavior without re-running the installer.

See `docs/CONFIG.md` for all keys and their defaults.

## How to run locally

```bash
# Clone
git clone https://github.com/jbcom/get-bashed.git ~/.get-bashed-dev
cd ~/.get-bashed-dev

# Test install into temp prefix
./install.sh --prefix /tmp/get-bashed-test --auto --force

# Run the full test suite
make test

# Lint
make lint

# Regenerate docs
make docs
```

## How to contribute

See `CONTRIBUTING.md` for the full guide. Quick summary:

1. Fork and create a branch.
2. Follow POSIX-safe conventions in `install.sh`; Bash 4+ elsewhere.
3. Add shdoc annotations for new public functions.
4. Run `make lint && make test` before pushing.
5. PR titles must follow Conventional Commits (`feat:`, `fix:`, `docs:`, etc.).

## Security

See `SECURITY.md` for the threat model and vulnerability reporting guidance.

## Docs

Full docs: `https://jonbogaty.com/get-bashed`

Generated API docs are in `docs/` and published to GitHub Pages via `docs.yml`.
