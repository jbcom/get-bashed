---
title: STATE.md — get-bashed
updated: 2026-04-15
status: current
---

# State

## Current phase

get-bashed is in production-hardening mode. The installer/runtime split is stable, and the current focus is on keeping the documented contract, CI behavior, and runtime behavior consistent across macOS, Linux, and WSL.

## Completed

- Modern Bash bootstrap from `install.sh`
- Docs-site release installer at `/install.sh`
- Managed install prefix under `~/.get-bashed`
- Ordered runtime module loading
- Centralized tool registry and dependency resolution
- Pinned `asdf` default versions for built-in language installers
- Generated installer/helper API docs plus a generated installer catalog
- Matrix CI across Ubuntu and macOS for lint, tests, install verification, docs generation, and docs build
- Dedicated Ubuntu-under-WSL validation on `windows-2025` for lint, tests, and install verification
- Checked-in release bundle packaging, release validation, published-release verification, and generated package manifests for `jbcom/pkgs`

## Active priorities

- Keep docs and code in lockstep
- Preserve unknown user-owned files during forceful reinstalls
- Pin external installer refs where feasible
- Keep pinned runtime defaults and test helper SHAs in the shared manifest
- Verify fallback download integrity when package managers are unavailable
- Realign managed git-backed installs to pinned refs on rerun
- Expand behavior-level tests for runtime modules and installer semantics
- Keep the docs/release/package-manager surface aligned as the release workflow evolves

## Remaining risk areas

- Optional startup behaviors such as `auto_tools` are now pinned, gated on tool availability, and avoid reinstalling already-present pinned npm packages, but still need periodic review for performance and predictability
- Pinned sources and runtime defaults still need periodic refresh as upstream projects release updates
