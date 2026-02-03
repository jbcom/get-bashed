# System Patterns

- Modular runtime: `bashrc` loads ordered `bashrc.d/*` modules.
- Config generation: `install.bash` writes `get-bashedrc.sh` and reads it at startup.
- Installers: centralized tool registry in `installers/tools.sh` with handlers in `_helpers.sh`.
- Profiles/features: profiles set defaults; features override; bundles expand installers.
- Secrets: sourced from `~/.get-bashed/secrets.d/*.sh` only.
- Optional deps: tool optional dependencies can be gated by config flags.
- Bootstrap: `install.sh` is POSIX-only and re-execs `install.bash`.
- Dotfiles: `--link-dotfiles` creates symlinks into `~/.get-bashed` and backs up existing files.
