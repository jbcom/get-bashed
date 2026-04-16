---
title: Getting Started
updated: 2026-04-15
status: current
---

# Getting Started

```{toctree}
:maxdepth: 1

downloads
install-and-verify
```

`get-bashed` now has two installation surfaces:

- the source-tree bootstrap at the repository root, for contributors and local development
- the release installer at the docs site root, for end users and package-manager distribution

The canonical published assets are:

- `get-bashed-<version>-unix.tar.gz`
- `get-bashed-<version>-windows.zip`
- `checksums.txt`

Use the docs-hosted installer for normal installs:

```bash
curl -fsSL https://jbcom.github.io/get-bashed/install.sh | sh
```

Use the repo-root `install.sh` when you are working from a checkout and want the current tree rather than a released bundle.
