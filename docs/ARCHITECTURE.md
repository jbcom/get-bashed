---
title: ARCHITECTURE.md — get-bashed
updated: 2026-04-10
status: current
---

# Architecture

get-bashed is designed with a strict separation between the **installer** (idempotent setup) and the **runtime** (shell startup logic).

## Layer 1: Installer

### Entry Points

```
install.sh      POSIX sh bootstrap (#!/bin/sh, set -eu)
install.bash    Full installer, Bash 4+ (set -euo pipefail)
```

`install.sh` locates or installs bash (brew/apt/dnf/yum/pacman), then re-execs `install.bash` using the best available bash binary. This two-stage design keeps the bootstrap POSIX-safe while allowing the installer to use modern Bash features.

### Installer Flow

```
install.bash
  1. Parse CLI arguments
     --profiles, --features, --install, --link-dotfiles,
     --name, --email, --vimrc-mode, --with-ui, --auto, --yes,
     --prefix, --force, --dry-run, --list*
  2. Apply profiles (sets feature flag defaults)
     profiles/minimal.env | dev.env | ops.env
  3. Apply feature overrides (CLI --features always win)
  4. Optional: interactive UI (dialog checklist or plain prompts)
  5. Copy bashrc.d/, dotfiles to PREFIX (~/.get-bashed)
  6. Bootstrap secrets.d/00-local.sh if missing
  7. Write PREFIX/get-bashedrc.sh (resolved feature flags)
  8. Apply git identity to PREFIX/gitconfig
  9. Link dotfiles to $HOME (--link-dotfiles) or inject source
     snippets into ~/.bashrc and ~/.bash_profile
 10. Run tool installers in dependency order
```

### Tool Registry

`installers/tools.sh` is the single source of truth for all installable tools. Each tool is declared using helper functions:

```
tool_register  id desc deps platforms methods
tool_pkgs      id brew apt dnf yum pacman
tool_git       id url
tool_curl      id url cmd
tool_handler   id function-name
tool_opt_deps  id "FLAG:dep,..."
tool_bin       id binary-name
```

`installers/_helpers.sh` provides:

- Platform detection (`_using_brew`, `_using_asdf`, `_using_git`, `_using_system`, etc.)
- Package manager wrappers (`brew_exec`, `apt_install`, `dnf_install`, `yum_install`, `pacman_install`, `pipx_install`, `pkg_install`)
- Custom tool handlers (`install_asdf`, `install_vimrc`, `install_shdoc`, `install_actionlint`, `install_gnu_tools`, `install_nodejs`, `install_python`, `install_java`)
- `asdf_has_plugin`, `asdf_install_plugin` helpers
- `component_install` — resolves a term through bash-it, asdf, brew, and system package managers with git/curl fallback
- `install_tool` — dispatches to the appropriate installation method from the registry

### Dependency Resolution

`install.bash` implements a depth-first dependency installer:

1. For each requested tool, fetch its `TOOL_DEPS` and any `TOOL_OPT_DEPS` gated by active feature flags.
2. Recursively install dependencies first.
3. Detect circular dependencies (tracked via `INSTALL_IN_PROGRESS` associative array).
4. Mark completed tools in `INSTALL_DONE` to avoid repeat installs.

### Config Generation

After wiring, `install.bash` writes `PREFIX/get-bashedrc.sh` containing:

```bash
export GET_BASHED_GNU=0|1
export GET_BASHED_BUILD_FLAGS=0|1
export GET_BASHED_AUTO_TOOLS=0|1
export GET_BASHED_SSH_AGENT=0|1
export GET_BASHED_USE_DOPPLER=0|1
export GET_BASHED_USE_BASH_IT=0|1
export GET_BASHED_GIT_SIGNING=0|1
export GET_BASHED_VIMRC_MODE="awesome|basic"
# optional:
export GET_BASHED_USER_NAME="..."
export GET_BASHED_USER_EMAIL="..."
```

This file is sourced by `bashrc` before loading any modules. Modules read these flags to conditionally enable behavior.

## Layer 2: Runtime

### Entry Points

```
bashrc          Sourced by ~/.bashrc (interactive shells)
bash_profile    Sourced by ~/.bash_profile (login shells)
bash_aliases    Sourced by bashrc (aliases)
```

`bash_profile` initializes Homebrew shellenv (if available), then delegates to `bashrc`.

`bashrc` has an include guard (`GET_BASHED_SOURCED`) to prevent double-sourcing. It sources `get-bashedrc.sh`, `bash_aliases`, then iterates `bashrc.d/[0-9][0-9]-*.sh` in sorted order.

### Module Load Order

| Range | Module | Purpose |
|---|---|---|
| `00-options.sh` | Shell options | `shopt`, `HISTIGNORE`, `EDITOR`, fd limit |
| `10-helpers.sh` | Helper functions | `_maybe_source`, `_path_add_front`, etc. |
| `20-path.sh` | PATH construction | Homebrew, `~/.get-bashed/bin`, asdf shims |
| `30-buildflags.sh` | Build flags | `CPPFLAGS`, `LDFLAGS`, `PKG_CONFIG_PATH` (conditional on `GET_BASHED_BUILD_FLAGS`) |
| `40-completions.sh` | Completions | Bash completion sourcing |
| `50-tool-init.sh` | Tool init | Cargo env, starship, direnv |
| `60-asdf.sh` | asdf | Version manager activation |
| `65-tools.sh` | Optional tools | Auto-install optional CLIs (conditional on `GET_BASHED_AUTO_TOOLS`) |
| `66-doppler.sh` | Doppler | Doppler init (conditional on `GET_BASHED_USE_DOPPLER`) |
| `70-bash-it.sh` | bash-it | Framework activation (conditional on `GET_BASHED_USE_BASH_IT`) |
| `70-env.sh` | Environment | General env vars |
| `80-aliases.sh` | Aliases | Extended alias definitions |
| `90-functions.sh` | Functions | Shell utility functions (`ex` extractor, `doppler_shell`) |
| `95-ssh-agent.sh` | SSH agent | Agent reuse or auto-start (conditional on `GET_BASHED_SSH_AGENT`) |
| `99-secrets.sh` | Secrets | Sources all `secrets.d/*.sh` files |

## Data Flow

```
User machine                           ~/.get-bashed/
  install.sh  ---->  install.bash  --> bashrc.d/
                                   --> bashrc, bash_profile, bash_aliases
                                   --> inputrc, vimrc, gitconfig
                                   --> get-bashedrc.sh  (generated)
                                   --> secrets.d/00-local.sh  (bootstrapped)
                                   --> vendor/  (git-cloned tools)
                                   --> bin/  (installer-placed tools)

Shell startup
  ~/.bashrc  --> ~/.get-bashed/bashrc
                   --> get-bashedrc.sh
                   --> bash_aliases
                   --> bashrc.d/00-options.sh
                   --> bashrc.d/10-helpers.sh
                   --> ... (in order)
                   --> bashrc.d/99-secrets.sh
                         --> secrets.d/00-local.sh
                         --> secrets.d/*.sh
```

## Directory Layout

```
/
  install.sh           POSIX bootstrap
  install.bash         Full installer
  bashrc               Runtime entrypoint (interactive)
  bash_profile         Runtime entrypoint (login)
  bash_aliases         Aliases
  inputrc              Readline config
  vimrc                Vim config template
  gitconfig            Git config template
  Makefile             docs, lint, test targets
  bashrc.d/            Ordered runtime modules
  installers/
    tools.sh           Tool registry
    _helpers.sh        Platform helpers and handlers
  profiles/
    minimal.env        Minimal profile
    dev.env            Developer profile
    ops.env            Ops profile
  bin/                 Portable helper scripts
  scripts/
    ci-setup.sh        CI tool bootstrap
    gen-docs.sh        shdoc doc generation
    package.sh         Release tarball builder
    pre-commit-ci.sh   Pre-commit CI runner
    test-setup.sh      Bats library fetcher
    verify-install.sh  Install wiring validator
  tests/               BATS test suite
    lib/               Pinned bats-support, bats-assert, bats-file
  docs/                Generated and hand-authored docs
  secrets.d/           Local secrets (git-ignored)
  .github/workflows/   CI/CD workflows
```

## External Dependencies

| Dependency | Role | Required |
|---|---|---|
| bash 4+ | Installer and runtime | Yes (installed by bootstrap if missing) |
| git | Cloning vendor tools, asdf | For bash-it, vimrc, asdf, shdoc installs |
| curl | Brew installer, actionlint download | For brew/actionlint installs |
| brew / apt / dnf / yum / pacman | Package installation | At least one recommended |
| asdf | Multi-version language management | Optional, preferred for nodejs/python/java |
| shdoc | Documentation generation | Dev only (make docs) |
| bats | Testing | Dev only (make test) |
| pre-commit | Linting | Dev only (make lint) |

## Security Boundaries

- `install.sh` / `install.bash`: runs with user privileges. No sudo unless a package manager requires it.
- Tool installers: call system package managers (which may require sudo) or install to `~/.get-bashed/`.
- `secrets.d/`: sourced as shell code with user privileges. Content is never committed.
- All git clones use `--depth=1` to minimize exposure.
- All curl downloads use `-fsSL` (fail on error, silent, follow redirects) with no verification bypass.
