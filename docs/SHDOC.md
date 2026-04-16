---
title: SHDOC.md — get-bashed
updated: 2026-04-15
status: current
---

# shdoc

get-bashed uses `shdoc` to generate installer-facing shell API docs.

## Install

Preferred:

```bash
./install.sh --install shdoc
```

If the package manager does not provide `shdoc`, the installer falls back to a pinned git ref and installs the script into `GET_BASHED_HOME/bin` with a portable `gawk` shebang.

## Generate

```bash
make docs
```

For direct script usage, `./scripts/gen-docs.sh` still works when `shdoc` is already on `PATH`.

This regenerates:

- `docs/INSTALLER.md`
- `docs/INSTALLERS_HELPERS.md`
- `docs/INSTALLERS.md`

`docs/MODULES.md` is maintained manually.
