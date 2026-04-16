# installers

Installers are defined in `installers/tools.sh` as a registry.
Pinned sources and default runtime versions live in `installers/sources.sh`.

Each tool declares:
- ID, description, deps, platforms
- supported install methods (brew/apt/dnf/yum/pacman/pipx/git/curl/handler)
- optional package name overrides

Handlers are exposed through `installers/_helpers.sh` and implemented in `installers/lib/`.
