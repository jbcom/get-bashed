---
title: get-bashed
updated: 2026-04-15
status: current
---

# get-bashed

## The Bash-First Shell Bundle for macOS, Linux, and WSL

`get-bashed` is a managed Bash environment with a POSIX bootstrap, an ordered runtime module tree, and a reproducible installer registry. The public docs site is now also a release surface: it hosts `/install.sh`, documents the published release bundles, and tracks the package-manager manifests pushed into `jbcom/pkgs`.

```bash
curl -fsSL https://jbcom.github.io/get-bashed/install.sh | sh
```

That docs-hosted installer resolves the latest GitHub Release, downloads the published Unix bundle, verifies `checksums.txt`, extracts the release tree, and then execs the bundled `install.sh`.

```{toctree}
:maxdepth: 2
:caption: Docs

getting-started/index
reference/index
api/index
```

```{toctree}
:hidden:

README
ARCHITECTURE
SHDOC
TESTING
```

## Release Surface

- [GitHub Releases](https://github.com/jbcom/get-bashed/releases) publish the canonical archives plus `checksums.txt`.
- `docs/public/install.sh` is copied to the docs site root as `install.sh`.
- `cd.yml` follows the GitHub-recommended draft-first path: create the draft release, attach the validated assets, publish the draft, verify the published surface, then open the `jbcom/pkgs` PR.

## Product Contract

- `install.sh` is POSIX `sh` and bootstraps Bash 4+ before handing off to `install.bash`.
- `--dry-run` is zero-write.
- `--force` preserves unknown user-owned files under `~/.get-bashed`.
- Doppler integration is explicit-only.
- `asdf` works for both Homebrew and git installs.

## Source-Tree Reference

If you are working from a checkout instead of a published release, the original repo-owned reference pages still live here:

- [README](README.md)
- [Architecture](ARCHITECTURE.md)
- [Design](DESIGN.md)
- [Configuration](CONFIG.md)
- [Runtime Modules](MODULES.md)
- [Testing](TESTING.md)
- [State](STATE.md)
- [Shell Docs](SHDOC.md)
