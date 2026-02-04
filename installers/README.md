# installers

Installers are defined in `installers/tools.sh` as a registry.

Each tool declares:
- ID, description, deps, platforms
- supported install methods (brew/apt/dnf/yum/pacman/pipx/git/curl/handler)
- optional package name overrides

Handlers live in `installers/_helpers.sh` for tools that need custom logic.
