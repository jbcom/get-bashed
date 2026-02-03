# System Patterns

- Modular runtime: `bashrc` loads ordered `bashrc.d/*` modules.
- Config generation: installer writes `get-bashedrc.sh` and reads it at startup.
- Installers: centralized tool registry in `installers/tools.sh` with handlers in `_helpers.sh`.
- Profiles/features: profiles set defaults; features override; bundles expand installers.
- Secrets: sourced from `~/.get-bashed/secrets.d/*.sh` only.
- Optional deps: tool optional dependencies can be gated by config flags.
