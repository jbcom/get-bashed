# System Patterns

- Modular runtime: `bashrc` loads ordered `bashrc.d/*` modules.
- Config generation: installer writes `get-bashedrc.sh` and reads it at startup.
- Installers: dependency-aware scripts with metadata and helper functions.
- Profiles/features: profiles set defaults; features override; bundles expand installers.
- Secrets: sourced from `~/.get-bashed/secrets.d/*.sh` only.
