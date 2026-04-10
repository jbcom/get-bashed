---
title: ARCHITECTURE.md — get-bashed
updated: 2026-04-10
status: current
---

# Architecture

get-bashed is designed with a strict separation between the **installer** (idempotent setup) and the **runtime** (shell startup logic).

## System Patterns

- **Modular Runtime**: `bashrc` acts as an orchestrator that loads ordered modules from `bashrc.d/`.
- **Generated Configuration**: Choices made during installation are persisted in `get-bashedrc.sh`, ensuring the runtime is decoupled from the installer's logic.
- **Centralized Registry**: A single source of truth (`installers/tools.sh`) defines all tool metadata and dependencies.
- **Isolated Secrets**: Secrets are sourced exclusively from `~/.get-bashed/secrets.d/`, keeping them out of the main configuration flow.
- **Idempotent Symlinking**: Dotfiles are symlinked into `~/.get-bashed` rather than copied, allowing for clean updates and easy backups.

## Non-Goals

- **Global Path Hardcoding**: The project must remain portable and avoid hardcoding user-specific paths or system-wide locations.
- **Automatic Secret Sourcing**: For security, secret providers like Doppler or 1Password are never auto-sourced at shell startup.
- **Replacing Dotfile Managers**: get-bashed is a modular environment, not a competitive replacement for general-purpose dotfile managers.

## Layer 1: Installer

### Entry Points
`install.sh` (POSIX sh) locates or installs a modern Bash, then re-execs `install.bash` (Bash 4+). This ensures broad compatibility without sacrificing modern shell features during installation.

### Installer Flow
1. **Argument Parsing**: Resolves profiles, features, and tool lists.
2. **Profile Application**: Applies standard presets (`minimal`, `dev`, `ops`).
3. **Feature Resolution**: Overlays specific feature flags.
4. **Environment Setup**: Copies runtime modules and dotfiles to the installation prefix.
5. **Config Generation**: Writes `get-bashedrc.sh` with resolved flags.
6. **Tool Installation**: Executes installers in strict dependency order.

## Layer 2: Runtime

### Startup Sequence
`~/.bashrc` sources `~/.get-bashed/bashrc`, which performs the following:
1. **Config Load**: Sources `get-bashedrc.sh` to populate feature flags.
2. **Alias Load**: Sources `bash_aliases`.
3. **Module Iteration**: Sources `bashrc.d/[0-9][0-9]-*.sh` in sorted order.

### Module Load Order

| Range | Purpose |
|---|---|
| `00-` | Shell options and core environment |
| `10-` | Shared helper functions |
| `20-` | PATH construction |
| `30-` | Build flags (conditional) |
| `50-` | Tool initialization (starship, direnv) |
| `60-` | Version management (asdf) |
| `70-` | Frameworks (bash-it) and general env |
| `90-` | Shell functions |
| `95-` | SSH agent management |
| `99-` | Local secrets sourcing |

## Data Flow

```{mermaid}
graph TD
    A[install.sh] --> B[install.bash]
    B --> C[~/.get-bashed/get-bashedrc.sh]
    B --> D[~/.get-bashed/bashrc.d/]
    
    E[Shell Startup] --> F[~/.bashrc]
    F --> G[~/.get-bashed/bashrc]
    G --> C
    G --> D
```

## Security Boundaries

- **User Privileges**: All scripts run with current user permissions; `sudo` is used only by package managers.
- **Isolated State**: `secrets.d/` is strictly local and git-ignored.
- **Network Safety**: Downloads use `curl -fsSL` and follow redirects without verification bypass.
