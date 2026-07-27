---
title: Downloads
updated: 2026-04-15
status: current
---

# Downloads

## Release Assets

Each GitHub Release publishes:

- `get-bashed-<version>-unix.tar.gz`
- `get-bashed-<version>-windows.zip`
- `checksums.txt`

The Unix archive is the canonical bundle for macOS, Linux, and Linuxbrew/Homebrew installs. It contains the managed shell tree plus the POSIX bootstrap and can be unpacked and run directly.

The Windows archive ships the same managed shell tree plus `get-bashed.ps1` and `get-bashed.cmd`, which invoke the bundled installer through WSL when available and fall back to `bash.exe` from Git Bash when present.
The docs-site `install.sh` is for Unix-like shells; Windows users should use WSL, the release bundle wrappers, Scoop, or Chocolatey instead of running it from MSYS or Git Bash.

## Docs Installer

The docs site publishes [`/install.sh`](https://jbcom.github.io/get-bashed/install.sh). That script:

1. resolves the latest release tag unless you pin `--version`
2. downloads `get-bashed-<version>-unix.tar.gz`
3. verifies the bundle against `checksums.txt`
4. extracts the release tree
5. execs the bundled `install.sh`

## Package Managers

Package-manager manifests are generated from the release workflow and published to `jbcom/pkgs`:

- `brew tap jbcom/pkgs && brew install get-bashed`
- `scoop bucket add jbcom https://github.com/jbcom/pkgs && scoop install get-bashed`
- `choco install get-bashed`

Homebrew installs the Unix bundle and wraps `install.sh` from `libexec`.

Scoop and Chocolatey install the Windows wrapper bundle. Those channels expect WSL for the real Bash runtime and treat Git Bash as a fallback launcher, not the primary support target.
