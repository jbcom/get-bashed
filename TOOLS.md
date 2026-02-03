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

Example:
```bash
asdf plugin add nodejs
asdf install nodejs lts
asdf set --home nodejs lts
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

`bashrc.d/65-tools.sh` includes a helper to install optional CLIs using Node:
- `@google/gemini-cli`
- `@sonar/scan`

## Doppler (Optional)

If you use Doppler for secrets, install the CLI and enable:

```bash
GET_BASHED_USE_DOPPLER=1
```

You can install via the installer:

```bash
./install.sh --install doppler
```

Note: we do not auto-source doppler in shell init. Use `doppler_shell` to start a doppler-enabled subshell.

## Curation Policy

- Keep `bin/` small and portable.
- Prefer scripts that are OS-safe, dependency-light, and non-sensitive.

## Installer UI

If you pass `--with-ui`, the installer will try to use a curses UI (`dialog`).
If `dialog` is not present, it will attempt to install it using the system package
manager (Homebrew, apt, dnf, yum). Otherwise it falls back to plain prompts.

## Listing and Dry Run

- `./install.sh --list` shows the catalog of installers.
- `./install.sh --list-profiles` shows available profiles.
- `./install.sh --list-features` shows available features.
- `./install.sh --list-installers` shows the installer catalog.
- `./install.sh --dry-run --install <list>` shows what would be installed.

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
- `dev_tools`
- `ops_tools`

## Language Installers

Installers exist for `nodejs`, `python`, and `java`. If `asdf` is installed, they
will use it. Otherwise they fall back to the system package manager.

## Profiles

Use `--profiles minimal|dev|ops` to apply presets before any manual selections.
